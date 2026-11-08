# 端口矩阵组装的实解析性审查

四项结论中，**2 项成立，2 项需补假设，0 项不成立**。计数按委托中的四个问题。第 3 项所问的归一化标架结论成立，原稿为它给出的一个全板表达式有反例。实际代理矩阵含两个完全相同的列，因此满列秩论证无法用于这份代码。精确秩恒定即可覆盖这种情形。

| 项 | 判定 | 理由 |
|---|---|---|
| 1. 实解析延拓、实根及其阶数 | 成立 | 覆盖闭面板及其端点的实解析幂级数可逐项复化并粘合。实根处首个非零 Taylor 系数的次数与全纯延拓的零点阶数相同。 |
| 2. 无 Wood 点的实频代理核 | 需补假设（H-1） | 固定几何给出实解析的代理系统与右端。还需控制精确伪逆的秩，或指定解析的降秩模型并核对数值样值。 |
| 3. Müller 求解、提取、铅笔、标架与缩放 | 需补假设（H-2、H-3） | 实际求逆的块须可逆，所选簇须在整个面板上与单位圆分离且维数为 $K$，两侧参考坐标须有效。任意 QZ 基在归一化中确实消去。 |
| 4. 应区分精确函数与浮点样值 | 成立（原备注遗漏 H-4） | 谱阶数属于精确函数。搜索的验收量另受行列式样值误差与多项式近似误差影响。 |

第 1 项中，闭面板的实解析性包括端点处的实解析函数芽。以各实点为中心复化其收敛幂级数，在相交圆盘上由恒等定理粘合，得到该面板的复开邻域。延拓允许复值，实频行列式无需取实值。紧面板因而有某个 Bernstein 椭圆可供插值收敛分析，椭圆大小与函数上界决定实际收敛速度。定理 `thm:bordered`(3) 仍使用自身的条件：非 Wood 的 Cauchy 坐标、满列秩标架、孤立的 Dirichlet 块零点，以及取阶时有定义且非恒零的亚纯行列式。在此条件下，局部全纯延拓足以应用行列式恒等式及其阶数关系。

## H-1　代理拟合需要秩条件，当前矩阵恒有重复列

**形式 3，缺少假设（important caveat）。** `sec-closure.tex:169–172` 写道 “For a full-rank least-squares fit this is plausible, because $(A^*A)^{-1}A^*$ is real-analytic in real $k$ when $A$ is.” 该公式需要满**列**秩。`+kernel/precomp_proxy.m:50–56` 同时把 $(x_{\min},y_{\min})$ 放在第一和最后一个代理点。这两点在第 118–129 行产生逐项相同的核值及导数，故 $A(k)(e_1-e_{N_{\rm proxy}})=0$ 对所有 $k$ 成立。当前默认尺寸为 $960\times450$，其中第 1 列和第 320 列相同（`search_i9_config.m:14–15`，`precomp_proxy.m:71–74`）。这给出精确秩的上界 449。若要证明它恰等于 449，可取 $V$ 为已知零向量 $e_1-e_{320}$ 的正交补的固定正交基，并给出整个面板上 $\sigma_{\min}(AV)>0$ 的下界。源码未进行这一检查。

**精确拟合的修正。** 在固定离散化下，代理系统的 Hankel 项在所用非零距离及正实 $k$ 附近解析，所有端口和代理平面波阶均采用局部解析的非 Wood 根。矩阵与右端因此实解析（`precomp_proxy.m:59–69,94–143`）。若 $A$ 在面板邻域的实轴上精确秩恒为 $r>0$，局部取 $r$ 个独立列组成 $C$，则 $A=CD$，其中 $D=(C^*C)^{-1}C^*A$ 满行秩。最小范数最小二乘解为
$$
 A^+b=D^*(DD^*)^{-1}(C^*C)^{-1}C^*b .
$$
先将 $b$ 正交投影到 $\operatorname{ran} C$，再求解满行秩的 $Dx=C^+b$，即得此式。各因子对实 $k$ 实解析，恒为零秩的情形亦成立。复化共轭转置时使用 $C^\sharp(z)=\overline{C(\bar z)}^{\,T}$。直接将复 $z$ 输入最小二乘例程一般给出另一个函数。恒秩是对任意解析右端的充分条件；个别右端可以抵消秩变化。固定源点和目标点时，核的回卷整数、区域选择及 Kress 对角处方都由几何决定，因此已证明的系数解析性传递给离散核及使用的正则对角项。见 `+kernel/qpgreen_mfs_pairmat.m:84–116,124–143` 与 `+op/construct_A_QP.m:79–101,107–122`。

**数值秩的反例。** 令 $\tau=2\,\mathrm{eps}(1)$，在 $1/2<k<3/2$ 上取 $A(k)=\operatorname{diag}(1,\tau k)$、$b=e_2$。精确秩恒为 2，精确解为 $e_2/(\tau k)$。对此矩阵，默认 `pinv` 阈值恰为 $\tau$。即使其余算术精确，仅保留奇异值大于阈值的规则也会在 $k\le1$ 给出零，在 $k>1$ 给出 $e_2/(\tau k)$。这是阈值规则自身的跳变。是否在实际面板发生，不能由几个采样点的秩判定。

`precomp_proxy.m:149–153` 优先调用无显式容差的 `lsqminnorm`，后备调用 `pinv`。本机 MATLAB R2023b 的 `matfun/lsqminnorm.m:8–22,89–100` 使用完全正交分解（COD）及基于 QR 的秩判定，`matfun/pinv.m:18–35` 使用 SVD 与默认阈值。两条路径的秩规则有别。若**另行定义**截断 SVD 为精确模型，在整个面板上由阈值分开的固定保留奇异值簇也足够：$A^*A$ 的该簇谱投影及其上的逆实解析，簇内重根允许存在。对截断 COD，须明确产生解析低秩近似的列空间选择，例如固定独立主元列并保持相应块非奇异。仅记录一个数值秩整数不能识别这些空间，也不能证明所得样值逼近原来的 $A^+b$。默认规则可与 [MathWorks 的 lsqminnorm 文档](https://www.mathworks.com/help/matlab/ref/lsqminnorm.html) 和 [pinv 文档](https://www.mathworks.com/help/matlab/ref/pinv.html) 对照。

## H-2　除无 Wood 点外，组装所用逆和面板坐标都需存在

**形式 3，缺少假设（important caveat）。** `sec-closure.tex:164–172` 对组装仅讨论了代理求解。对于引线，即便 $A_\eta(k)$ 的每个条目实解析，`+bloch/construct_S.m:132–160` 计算的密度仍含 $A_\eta^{-1}B_{\rm inc}$。无 Wood 点只保证通道根及 $1/\gamma_m$ 的局部解析性。矩阵求逆在奇异点可能产生极点，例如标量 $A_\eta(k)=k-k_0$、$B_{\rm inc}=1$。分排拼接时还对 $I-R_{\rm R}^{(1)}R_{\rm L}^{(2)}$ 求逆。最小修正是要求每次**实际使用**的求解在整个面板有效。

| 源码位置 | 具体条件与作用 |
|---|---|
| `+op/construct_A_QP.m:69–101,178–183,252–259,323–334`，`+bloch/farfield_extractors.m:109–126` | 固定节点、非退化几何、解析代理及固定实频根分支给出解析的有限矩阵。Kress 对角使用正则公式，提取器的分母为非零 $\gamma_m$。 |
| `test/bie-bound/pole-free-v1/search_i9_physics.m:45–47,225–236,367–376`，`border_data.m:9–19` | 引线密度求解及使用的排间消元须可逆。增广中心直接装入密度方程，组装 $\mathsf H$ 本身允许中心 $A_\eta$ 或引线 Dirichlet 块奇异。 |
| `sec-leads.tex:17–24,177–193`，`search_i9_physics.m:113–143` | 每侧取朝外铅笔，左侧交换 $A,B$。要求 $\zeta B-A$ 在整个面板及整个单位圆上可逆，并在一个基点确认圈内簇维数为 $K$。连续性使该维数恒定。共同的非零 QZ 缩放保持投影。 |
| `border_matrix.m:5–14`，`border_search.m:8–12,81–89` | $Z_0$ 在每个面板固定，$Z_0^*Z(k)$ 须处处可逆。中点生成的行、列缩放须有限且非零。代码在实际访问的频点检查重叠，阈值 $0.05$、$20$ 是数值验收条件。 |

## H-3　有效的重叠坐标不能保证 $\mathscr P(k)Z_0$ 是全板标架

**形式 2，反例（blocker，仅针对指定的全板标架证明）。** `sec-closure.tex:149–152` 写道 “It equals $F(k)(\mathsf Z_0^*F(k))^{-1}$ for the holomorphic frame $F=\mathscr P\mathsf Z_0$ … wherever the overlap … is invertible.” Riesz 投影通常是斜投影。以下反例连面板中点锚定和代码的重叠阈值都满足。

令 $t=k-k_0\in[-1,1]$，$k_0>1$，取
$$
 v(t)=(1,t)^T,\quad P(t)=v(t)[\,1-t,\ 1\,],\quad T(t)=2I-\tfrac32 P(t).
$$
因 $[1-t,1]v(t)=1$，$P$ 是铅笔 $(T,I)$ 对圈内乘子 $1/2$ 的 Riesz 投影，另一个乘子恒为 $2$。中点参考基为 $Z_0=e_1$。取 $Z(t)=v(t)/\sqrt{1+t^2}$，则 $Z_0^*Z(t)\ge1/\sqrt2$，其条件数恒为一，而 $P(1)Z_0=0$。于是原文右式在 $t=1$ 含有奇异逆，实际归一化 $Z(t)(Z_0^*Z(t))^{-1}=v(t)$ 却在整个面板上解析。此例也可写成散射铅笔，因为传递矩阵的 $T_{22}=2-3t/2$ 在面板上非零。

**修正。** 在任一点 $k_1$ 以其选定子空间的基 $V_1$ 造局部标架 $F_1(k)=\mathscr P(k)V_1$。固定围道上的逆局部一致全纯，故投影全纯，且 $F_1$ 在 $k_1$ 附近满列秩。仍使用原来的固定参考矩阵 $Z_0$。重叠可逆时，$Z(Z_0^*Z)^{-1}=F_1(Z_0^*F_1)^{-1}$，因为两基之间的可逆右因子在乘积中消去。局部表达式彼此一致，给出整个有效坐标上的实解析性及其全纯延拓。此论证允许簇内部的重根、Jordan 块和 QZ 基的任意换相。它与 [[port-subspace]] 第 294–315 行及 [[port-subspace-review]] 第 11 项一致。

## H-4　实解析性不能单独支持浮点验收

**形式 1，失败步骤（important caveat，影响数值验收的解释）。** `sec-closure.tex:167–169` 的 “so it needs only that the real-$k$ assembly is real-analytic” 对精确延拓足够，对实际搜索的精度则不足。`border_search.m:14–34,81–89` 插值的是按本层最大对数模统一缩放后恢复的复行列式值。LU 排列、对数模和相角各自可以换支，精确算术下恢复的量仍是同一行列式乘一个常数。实际样值误差还包括容差删秩的影响、快速多极求和、线性求解、QZ、行列式求值与舍入。

若归一化节点误差上界为 $\eta$，其对插值多项式的一致影响至多为 $\Lambda_n\eta$，其中 $\Lambda_n$ 为节点的 Lebesgue 常数。解释尾系数和离点检验时，需让相应误差低于各自的验收尺度。代码检验末三项相对系数 $10^{-10}$ 和两个离点的归一化绝对偏差 $10^{-9}$，没有计算整个面板的样值误差界。即使样值精确，有限抽查也不能推出找全实根：对某次面板检验的全部采样点 $k_j$ 和另外一点 $k_c$，多项式 $1-\prod_j(k-k_j)/\prod_j(k_c-k_j)$ 在所有采样点等于一，在 $k_c$ 等于零。最小修正是将全纯性用于精确函数的插值依据与零点阶数，将实际面板接受表述为受求值精度限制的经验判断。

## 可直接替换的备注

~~~latex
\begin{remark}[Analytic dependence of the assembly]\label{rem:holomorphy}
Fix the discretization on a closed positive-frequency panel free of Wood points for all orders used.
Assume the proxy matrix has constant exact rank on a real neighborhood of the panel. Its analytic data then give a real-analytic minimum-norm fit.
Assume all lead density solves and internal matching solves used in assembly are nonsingular there.
For each outward pencil (reversed on the left), assume separation on the unit circle with $K$ multipliers inside.
Use fixed reference matrices with invertible overlaps throughout the panel and finite, nonzero fixed scales.
In the argument above, $F=\mathscr P\mathsf Z_0$ works locally where it has full rank.
Near any $k_1$ use $F(k)=\mathscr P(k)\mathsf Z_\pm(k_1)$ with the same reference in \eqref{eq:frame}.
The framed exact matrix and its determinant thus extend holomorphically near the panel, as required by \cref{thm:bordered}(3).
The search needs determinant samples accurate on the scale of its interpolation tests.
Numerical rank decisions, fast summation and roundoff affect the samples. The tail and off-grid tests give empirical acceptance.
\end{remark}
~~~

## 次要备注

`sec-closure.tex:135–136` 的 “not even continuous” 可改为 “need not be continuous”。逐点 QZ 基允许不连续的选取，也允许连续的选取。这个区别不影响归一化后的矩阵。

Review literature verification completed. 本次仅写入本审查文件。
