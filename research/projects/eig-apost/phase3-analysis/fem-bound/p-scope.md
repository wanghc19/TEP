# FEM 原生场的无限波导谱距离：范围与验收

日期：2026-10-23。对应正文版本：**FEM-bound v2 / Revision B.1：非零通量与精度评价**。
工作树 `/Users/whc/Documents/Work/epost`，分支 `codex/epost`。
本轮完整重写旧专题的构造与验收；没有数值实验、求解器改写或主线晋升。
理论正文见 [[research/projects/eig-apost/phase3-analysis/fem-bound/theory|theory]]，
实际独立审查见 [[research/projects/eig-apost/phase3-analysis/fem-bound/r-theory|r-theory]]。

## 1. 冻结目标与权限

给定当前有限多胞元截断 FEM 交付的实候选 $k_h>0$ 及其原生场，令
$\mu_h=k_h^2$，构造精确算术下可计算的量，控制

$$
\operatorname{dist}(\mu_h,\sigma(A(\beta))).
$$

$A(\beta)$ 必须是原无限条带上的连续算子；不以有限域连续算子或 FEM 矩阵替代。
无需预知模态数、附近唯一性或真特征函数。若进一步主张点谱特征值存在，须另有
包含区间与本质谱不交的证明。本轮不完成这一可选升级。

**本轮的完成条件是可用于评价精度的具体上界方法。** 必须保留 PDE 抵消，给出有限维
辅助构造及可核验的小量机制；不能以一个正确但必然过大的后备估计宣布完成。
“理论上可随缺陷缩小”与“当前 I9.3 实际能给出多小的数值”是不同结论；后者本轮不评价。

- 仅研究“有限多胞元截断＋FEM”的后处理，不研究 FEM＋DtN 求解器。
- main 工作树只读；不改草稿、MATLAB、公共 package 或 `test/`，不创建实验目录。
- 不启动 MATLAB、Octave、FEM/BIE/FMM，不运行数值实验或安装依赖；允许解析推导和标量量级核算；
  不 stage、commit、push。
- 仅两个 subagent，设置均继承主 agent：Researcher 负责 `theory.md`；skeptic 在正文形成后独立只读审查，
  返回完整报告，由主 agent 机械保存为 `r-theory.md`，不改写其结论。
  主 agent 负责本文件、入口、状态和问题账目；互不覆盖。
- 证明使用 rigorous-proof 的 **Complete rewrite** 模式，审查使用 **Review only**；
  符号使用 notation-discipline 的 **Writing** 模式。定向文献核验采用 academic-research-suite；
  不由其通用工作流增加代理、另起综述或执行实验。

## 2. 入口与权威核对

已依次读取 root/research `AGENTS.md`、`research/README.md`、`STATUS.md`、`NOTATION.md`。
没有活动 `mainline/`；冻结 Müller--Cauchy 索引不是本轮的自动权威。
直接对象依据：

1. [[research/projects/eig-apost/implementation/i9/design-9-3a|I9.3 设计]]、
   [[research/projects/eig-apost/implementation/i9/review-9-3a|原 FEM 独审与 BIE 续作自检]]、
   [[test/i9/compare-v1/README|已交付输出说明]]。
2. `test/i9/compare-v1/fem_i9_config.m`，以及 `fem_i9_run.m` 的
   `LOCAL_curve`、`LOCAL_mesh`、`LOCAL_assemble`、`LOCAL_constraint`、`LOCAL_modes`、`LOCAL_export`。
3. [[research/projects/eig-apost/phase3-analysis/resolvent-bound/s-framework|现有预解式框架]]；
   main 最新工作树 `draft/zh/s-modelproblem.tex`、`s-error.tex` 的模型与谱距离定理，只读。
4. [[research/projects/eig-apost/implementation/i9/r-fem-lit|定向文献记录]]，以及其中
   Chaumont-Frelet (2025)、Giani (2013) 的本地原文。旧 residual/lift 实验不作为证明依据。

本轮开始时 epost HEAD 为 `0797cba`，工作树干净；上一版专题已由用户提交。
main HEAD 为 `f515860`，已有未提交的
`draft/zh/draft.tex`、`draft/zh/s-error.tex`；本轮读取的是当时最新工作文件，未改动它们。

| 核对项 | 本轮裁定 |
|---|---|
| 连续算子 | 沿用 main `eq:fixed-beta-operator` 的 $A(\beta)=-\rho^{-1}\Delta$；材料只在质量权重中 |
| main 的共同背景 | `s-modelproblem.tex` 用单一 $\rho_{\mathrm p}$；I9 两侧材料形状不同，分别保留，不套单背景本质谱等式 |
| 本质谱地位 | main `conj:essential-spectrum` 仍为猜想；本轮基本谱距离不使用它，也不使用有限采样 GAP 作为证明 |
| 算子与 pencil | main `s-error.tex` 开头出现 $A(\beta)=A(\beta,k)$；本轮连续 $A(\beta)$ 不依赖 $k$，不沿用这处混写 |
| 现有 BIE 公式 | 逐片 Helmholtz 场、界面缺陷和 trace 常数有特定假设；FEM 不满足这些场假设，须重新证明弱残差桥接 |
| 跳跃符号 | 最新 main `eq:raw-interface-jumps` 已是 $j=\partial_\nu u^{\rm in}-\partial_\nu u^{\rm out}$；不继承旧记录中已过时的符号冲突 |

## 3. 固定模型与原生场身份

沿用 $B=\mathbb R\times(-d/2,d/2)$、$\mathcal H=L^2(B,\rho\,\mathrm{d}x\,\mathrm{d}y)$、
$H^1_\beta(B)$、$A(\beta)$。当前 $\beta=0.5$、$d=L=1$，
背景、中心、左右 inclusion 的材料分别为 $1,4,17,17$；故 $1\le\rho\le17$。
中心 $\Omega_0$ 是单个单连通区域，参数曲线为

$$
x_0(t)=0.2(1.5+0.3\cos5t)\cos t,\qquad
y_0(t)=0.2(1+0.3\cos5t)\sin t.
$$

不另乘面积归一化因子。左右 lead 的局部参数为

$$
r_\pm(t)=\frac{0.2(1+a_\pm\cos3t)}{\sqrt{1+a_\pm^2/2}},\qquad
(a_-,a_+)=(0.12,0.20),
$$

曲线是 $r_\pm(t)(\cos t,\sin t)$ 在相应整数胞元中心的平移。
两侧同一全局朝向，不镜像，不交换；原无限材料按各侧分别周期延续。
$\Lambda_\pm$ 保留给 DtN；本轮不使用 $\Lambda$ 作求和指标。

I9.3 的有限矩形为 $B_6=(-6.5,6.5)\times(-0.5,0.5)$。
左右端齐次 Dirichlet，上下值满足 $u_h(x,0.5)=\exp(\mathrm{i}\beta d)u_h(x,-0.5)$。
P2 节点和边中点均施加约束；**源码没有施加逐点导数准周期条件**。
只凭值相容不能删去逐单元分部积分中的准周期导数缺陷。

每条材料界面用 80 段等参二次曲边表示；解析曲线上的顶点、中点不使整条二次弧成为解析界面。
源码梯度刚度为 $\int\nabla\phi_j\cdot\nabla\overline\phi_i$，质量为
$\int\rho_h\phi_j\overline\phi_i$，采用 $8\times8$ Duffy 求积。
这里 $\rho_h$ 是网格表示材料，区别于原解析几何上的 $\rho$。

本轮把保存的 reduced coefficients 与网格拓扑视作固定数据，按理论精确相位构造原生有限元函数；
不把浮点存储的相位误差悄悄当作精确准周期。主定理无需该函数是精确 Galerkin 特征向量。
零延拓所需的是全局有效、无重叠、覆盖矩形的相容网格和边界值约束，
不要求网格材料界面等于真实界面；也不要求人工端普通法向导数为零。
新版显式通量构造直接评价其人工端迹，不凭源码的中点公式假定保存几何准确为常速。
只有核验人工端二次边的几何中点确为两端点的算术中点后，
才使用常速仿射参数下的端迹投影收缩性简化估计；不移动原生节点以满足此条件。

已交付 $k_h=1.5584630910866906$。历史记录的
$\mu_{\rm num}=2.4288072062794823$ 是浮点乘积；理论始终用 $\mu_h=k_h^2$。
随后 BIE 重构得到的 $R_{\rm num}=0.11866142633964537$ 属于另一个场，
不作为 FEM 原生场误差、实际特征值误差或本轮界的输入。

## 4. 旧结论的保留与撤回

保留并复核零延拓、弱残差与原无限域谱距离转换。对 $s>0$、
$0<\underline U\le\|u\|_{\mathcal H}$ 和可靠弱残差上界 $\overline\eta_s$，令

$$
\tau=\frac{\overline\eta_s}{\underline U},\qquad
R_s=\frac{\tau}{2}\left(\tau+\sqrt{\tau^2+4(\mu_h+s)}\right).
$$

此前零通量及全域材料极值后备给出

$$
\tau_0^2\ge\frac{17\mu_h^2}{s},\qquad
R_{s,0}>\sqrt{17}\mu_h\approx10.0142.
$$

当 $s=\mu_h$ 时，甚至有

$$
R_{\mu_h,0}\ge\frac{\mu_h}{2}(17+\sqrt{425})\approx45.6804.
$$

原 $k$ 搜索窗口 $[1.45,2.25]$ 的平方窗口宽度仅 $2.96$。
以上是**估计式输出的下限，不是实际谱距离的下限**，无需执行全单元积分即可排除其作为本轮主方案。
旧稿“可能偏宽”“先评价后备再决定通量”“有限后备即完成精度评价”的建议撤回。
旧独审只覆盖旧版正确性及有限可评价性，**不能作为新版精度目标的 PASS**；本轮独审须对应实际 v2 正文。
$p=0$ 至多保留作有效性例子，不再作为完成依据或推荐的首次完整计算。

## 5. 新版验收标准

| 标准 | 必须交付的内容 |
|---|---|
| 无限域与函数空间 | 正的有界质量权重、闭形式、非负自伴算子；原生场的零延拓及其身份 |
| 完整证明 | 从弱缺陷到全谱距离；不把分布边源当作 $L^2$ 强残差 |
| 人工边界 | 左右端分别说明；内部边、材料边和准周期接缝不遗漏、不重复 |
| A：抵消 | 在同一残差内评价 $\operatorname{div}p+\mu_h\rho u$，并同时逼近 $\nabla u$；不分别支付全部梯度及质量能量 |
| B：小量机制 | 具体有限维通量空间、方程及显式有限构造；证明其上界由可核验缺陷控制，不能只引用未知最优通量或隐常数 |
| C：真实几何与积分 | 区分真实 $\rho$、网格 $\rho_h$；局部切割或失配控制及有限单侧积分，不能用全域 $[1,17]$ 包围毁掉抵消 |
| D：实施前筛选 | 解析检查固定下限、移位放大和人工端代价；已证明无分辨率的方案不推荐完整计算 |
| E：算法交接 | 指定阶数、Piola 映射、边方向、复准周期约束、目标系统、唯一性、不精确求解、输入/输出及有限步骤和规模 |
| 截断与收敛 | 分别标明体/跳跃缺陷、通量近似和人工端；固定截断不能凭网格加密声称无限域估计趋零 |
| 解释边界 | 基本全谱距离不依赖隔离；点谱解释另有条件；尚未实现不自动阻断理论，但必然无精度分辨率阻断本轮实用性结论 |
| 新版独审 | Researcher 的 v2 正文实际形成后，skeptic 对正确性/可计算性与实用性分别裁定，修订后必要时复审 |

允许先给精确积分定义，但最终须给有限数据评价路径及单侧误差控制。
原生场的整体缺陷可以统一估计，不强求唯一的“离散误差＋截断误差”分解。
本轮不要求某一具体上界、尖锐性或优于 BIE，也不交付 I9.3 新数值。
必须给出有限维机制及可核验的充分条件，说明哪些缺陷同时变小时上界随之变小；
若关键步骤未闭合，按其实际阻断范围记录，不用零通量后备替代。

## 6. 交付与最小下一步

具体定理、常数与评价步骤统一在 `theory.md`；独审裁定在 `r-theory.md`。
问题只集中维护于 [[research/projects/eig-apost/implementation/i9/README#FEM 原生场理论问题账目|I9 FEM 理论账目]]，
每项区分 `blocker`、`important caveat`、`minor caveat`，注明阻断范围、最小下一步和状态。
本轮结束不自动进入数值实现或实验阶段。
