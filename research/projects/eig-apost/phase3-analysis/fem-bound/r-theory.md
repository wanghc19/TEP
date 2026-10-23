# FEM 原生场谱距离上界：独立审查

日期：2026-10-23。模式：**Review only**。

保存说明：以下审查由本轮唯一 skeptic 实际独立完成，主 agent 机械保存其返回正文；
skeptic 保持只读，主 agent 未改写其审查结论。

## A. 审查对象与验收标准

对象为 [[research/projects/eig-apost/phase3-analysis/fem-bound/theory|theory]] 的命题 1、定理 2–3、推论 4–5及其文献、曲边几何和可计算性说明。最终核对版本为 550 行，SHA-256：

`c4e0140c33822b986ea7985232a12e15ba283ed5c224ad931b87751b628ec01c`

目标是在原无限条带的加权空间中，对有限截断曲边 $P_2$ 原生场建立可计算的全谱距离上界。验收要求包括明确假设、完整证明、全部常数、人工端处理和有限评价路径；不要求尖锐性、点谱存在、唯一模态或本轮数值评价。

已阅读适用 AGENTS、research 入口与符号说明、`p-scope.md`、I9.3 设计/审查/运行说明、`r-fem-lit.md`、现有 `resolvent-bound/s-framework.md`；只读核对 main 最新 `s-modelproblem.tex`、`s-error.tex` 及 FEM 的配置、几何、装配、约束、模式与导出源码。没有采用旧 residual/lift 记录作为证明依据。

本轮为独立理论审查，不是既有数值结果的再次认证。

## B. 结论

**PASS WITH CONDITIONS；置信度高，无未解决 BLOCKER。**

本稿达到本轮的理论验收标准：在明确、可有限核验的相容网格与边界条件下，给出了针对原无限算子的完整谱距离证明，并以零通量和多项式矩提供不含未知常数的有限后备评价。真实材料界面不等于曲边网格界面的问题已被正确处理：原生函数无需是精确 Galerkin 特征函数，而材料上下界足以给出保守可靠输入。条件性保留在 I9.3 实例化层面：尚未执行准确相位、全局网格资格及单侧积分评价，因此不能声称已取得该 candidate 的数值上界。

不需要修订数学证明后才能接受当前理论交付。

## C. 最强挑战

最可能使实际应用失效的是**保存的曲边数据未真正定义准确矩形上的相容非零函数**，或仍使用近似相位却宣称属于准确的 $H^1_\beta$。

若有单元重叠、覆盖缺口、公共边不一致或相位不匹配，零延拓的形式域身份及逐单元积分表达式都可能失效。旧面积总和、浮点 Jacobian 最小值和矩阵约束残差不能单独排除这些机制。

正文第 2 节已明确提出完整资格，并给出有限多项式/几何判定后备；故这是实例认证的待办条件，而非当前抽象定理的缺口。

## D. 审查发现

1. **IMPORTANT CAVEAT：I9.3 的精确输入资格尚未实例核验。**
   位置：第 2 节，行 97–125；第 7.4 节。源码使用坐标容差配对、浮点相位和普通算术几何检查。正文准确区分了这些证据与精确资格。当前没有发现实际网格不合法的证据；缺少的是本轮未执行的确认。
   最小下一步：固定已保存的代表向量，以准确相位重建 $P_\beta\mathbf c_h$，核验公共边、外边界、覆盖/无重叠及全参考单元正 Jacobian。只限制实例化，不阻断理论接受。

2. **IMPORTANT CAVEAT：既有质量归一化和 Duffy 积分不能作为新界的可靠标量输入。**
   位置：第 7.1–7.4 节；源码 `LOCAL_assemble`、`LOCAL_modes`。保存质量对应 $\rho_h$，并非自动对应真实 $\rho$；曲边刚度也不是多项式积分的直接精确值。正文没有混用两者。
   最小下一步：优先评价式 (21)–(23) 的多项式矩与 Jacobian 下界，得到 $\underline U_0$、$\overline\eta_{s,0}$；若另走较尖锐路线，再可靠处理真实材料或失配项。这里只缺实现和评价，没有残留未知常数。

3. **MINOR CAVEAT：保守后备的实用分辨率未知。**
   位置：第 7.2–7.3 节。$p=0$ 支付全部梯度能量，并使用材料极值；结果可能很宽。没有理由在未评价前声称其能够定位带隙模态，也没有理由据此否定其可靠性。
   最小下一步：先完成已有后备评价；只有精度目标需要时才构造相容非零通量。无需为当前验收展开新的理论支线。

4. **IMPORTANT CAVEAT：全谱包含尚未升级为点谱存在。**
   位置：第 5 节，行 319–323。main 的本质谱关系仍为猜想，且其共同背景与 I9 双侧不同 lead 不同。正文未把有限 band scan 或 FEM 局域性筛选用作本质谱排除。
   最小下一步：仅在将来要求点谱解释时，证明所得包含区间与同一原算子的本质谱不交。本轮不需要完成该升级。

## E. 规格与源码对应

核对结果支持正文对当前输出的解释：

- `LOCAL_curve` 分别保留负侧 $a_-=0.12$、正侧 $a_+=0.20$，同一全局朝向；中心保留单个未额外缩放的五瓣 inclusion。
- 刚度为普通梯度内积，材料只进入质量权重；没有误用 $\rho\partial_\nu u$ 传输条件。
- `LOCAL_constraint` 对上下顶点及边中点施加值准周期，并在左右端置零；没有逐点施加导数准周期。
- `LOCAL_export` 保存的 reduced coefficients、六节点几何、拓扑、约束索引足够重建理论输入；已有 BIE 密度不参与。
- 近似界面上的单元标签只决定原离散求解问题。第 7.1 节将同一个物理函数放入真实材料的形式，逻辑成立，因为最高阶扩散系数始终为 1。

没有发现正文与上述源码之间会使当前理论失效的规格错配。本轮未读取并重新计算全部原始数值数组，也未复跑旧独审。

## F. 经审查保留的结论

**零延拓成立。** 左右值迹为零消除一阶分布导数中的端面源，故延拓属于 $V=H^1_\beta(B)$；不要求普通法向导数为零，也不要求属于强算子定义域。

**人工端与准周期接缝没有遗漏。** 式 (7) 的两端外法向号、上/下共轭相位关系及内部跳跃号正确。值准周期本身不消去导数接缝。

**通量界的常数明确。** 对满足式 (8) 的 $H(\operatorname{div})$ 通量，式 (11) 的 Green 恒等式正确；直积 Cauchy–Schwarz 和全直线迹估计给出

$$
\eta_s\le
M_s(p)+(2\sqrt{s\rho_{\min}})^{-1/2}
\bigl(\|g_-\|_{L^2}+\|g_+\|_{L^2}\bigr).
$$

若选择零端通量，代价保留在体缺陷中；$p=0$ 没有暗中假设原场导数为零。

**谱测度转换成立。** 对 $u\in V$，

$$
\eta_s^2=\int\frac{(\lambda-\mu_h)^2}{\lambda+s}\,\mathrm d\nu_u(\lambda).
$$

利用 $\lambda+s\le\mu_h+s+|\lambda-\mu_h|$ 得到式 (18)，且上界 $\overline\eta_s$、下界 $\underline U$ 的方向正确。因此

$$
\operatorname{dist}(\mu_h,\sigma(A(\beta)))
\le
\frac{\tau}{2}\left(\tau+\sqrt{\tau^2+4(\mu_h+s)}\right),
\qquad
\tau=\frac{\overline\eta_s}{\underline U}.
$$

证明不需要离散特征函数展开、模态数或隔离信息。推论 4 的正分母公式也由 $w_s\in D(A)$ 独立成立，没有向旧 BIE 残差机械添加体项。

**有限后备确实闭合。** 二次等参几何使式 (21) 的质量分子至多六次、梯度分子至多四次；式 (23) 的参考三角形矩公式正确。正 Jacobian 下界、材料极值和非零场保证有限 $\overline\eta_{s,0}$ 与正 $\underline U_0$。曲边逆映射带来的分母已由 $\underline d_K$ 控制，没有遗留未知迹常数或真实界面误差。

**文献使用边界合理。** 已直接从本地 PDF 核对：

- Chaumont-Frelet，*A posteriori error estimates for the finite element discretization of second-order PDEs set in unbounded domains*，arXiv:2503.22297v1：§2.9、§3.1，Theorem 3.1、Corollary 3.2、Proposition 3.4、Theorem 3.5，PDF pp.6–9。人工端项、域外源项及平衡条件确实存在。Proposition 3.4 证明中的反应项加号与其式 (3.2)、(3.6) 不一致，本稿已注明且不依赖该步骤。
- Giani，*An a posteriori error estimator for hp-adaptive continuous Galerkin methods for photonic crystal applications*，Computing 95 (2013), 395–414，DOI `10.1007/s00607-012-0244-6`：Definition 3/式 (22)、Theorems 1–2，印刷 pp.403–404／PDF pp.9–10。正文准确保留了对齐网格、收敛假设、隐常数和余项限制。

两份 PDF 的 SHA-256 分别为：

- CF：`2d826c8858e563771549334e58b512e5162d1cb4a61b0d68a18afd22f45374c9`
- Giani：`70a3204942fae0ba0d6ebc118f71e03739b0eb5b1ade080e2b3e34ad676bc6ca`

## G. 最小后续门槛

当前理论可以接受，无需修证明。获准进入实现阶段后，只需先验证既有输入资格并评价式 (21)–(23)、式 (15)。这不要求重跑 FEM、扩大截断、构造 DtN、计算真实模态数或改用 BIE 场。

若后备界过宽，再实施相容通量及其可靠积分；不把这一可选改进作为当前通过条件。

## H. 问题移交与执行记录

问题统一维护在 [[research/projects/eig-apost/implementation/i9/README#FEM 原生场理论问题账目|I9 FEM 原生场理论问题账目]]，本审查不另建增长账目。建议：

| 项目 | 阶段与分类 | 阻断范围 | 最小检查／建议状态 |
|---|---|---|---|
| FB-1 网格与准确相位 | 实例化；important caveat | 未核验前不得宣布该输出已有证书 | 有限几何与约束核验；`PENDING IMPLEMENTATION` |
| FB-2 单侧积分 | 实例化；important caveat | 未评价前不得报告数值可靠界 | 先走多项式矩后备；`PENDING IMPLEMENTATION` |
| FB-3 通量改进 | 精度改进；minor caveat | 不阻断基础界 | 先评价后备再决定；`DEFERRED` |
| FB-4 本质谱 | 点谱升级；important caveat | 仅限制点谱解释 | 独立排除本质谱；`OUT OF CURRENT SCOPE` |

审查只进行了文本、源码、数学推导和 PDF 原文检查。PDF 最终通过现有 `pypdf` 只读提取；未安装依赖、未写实验代码、未运行 MATLAB/Octave/FEM/BIE/FMM 或数值 sanity check，未 stage、commit、push。

审查者未修改 `theory.md`、main 草稿或任何其他文件；没有新增证明环境、标签或输出文件。末次确认的正文哈希见 A 节。当前没有待核验的依赖文献，也没有未闭合的主定理证明义务。

**Review literature verification completed.**
