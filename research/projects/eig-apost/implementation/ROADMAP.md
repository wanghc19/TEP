# Eigenvalue a posteriori implementation roadmap

本页只维护新路线的项目级阶段、依赖关系和退出条件。I1 的离散 readiness 见
[[research/projects/eig-apost/implementation/i1/README|I1 guide]]，I2 的四里程碑和 I2.1
count-one 结果见 [[research/projects/eig-apost/implementation/i2/README|I2 guide]]；实验物理路径由
[[test/README|experiment index]] 维护。

## 阶段依赖

$$
\mathrm{I1\ discrete\ operator\ readiness}
\longrightarrow
\mathrm{I2\ root\ isolation}
\longrightarrow
\mathrm{I3\ estimator/effectivity}
\longrightarrow
\mathrm{I4\ independent\ validation}.
$$

| Stage | 项目级目标 | 主要依赖 | 退出条件 |
|---|---|---|---|
| I1 | 把连续 DtN/BIE pencil 变成可审计的离散 $A_{\mathrm{def}}(k)$，并完成 half-guide graph/DtN、解析 chart 和 locator readiness | 连续 $\mathcal F(k)$；合格 one-cell blocks；固定 Fourier trace space；ordered-QZ stable subspace 与 chart policy | 静态组装、经验型参数连续性、平衡不变性和 sampled 小复圆盘 readiness 通过；若 $A_{\mathrm{def}}'$ 或 production separation 未完成，分别限制 derivative-based Newton 和 perturbation-certified claim，不阻止 derivative-free empirical isolation |
| I2 | 隔离并求出第一个离散 guided root candidate，验证 simple-root 条件并跨相邻 levels 匹配 | 当前 I1 exit | count-one contour、收敛离散 root、非零左右导数配对和跨层 mode matching 通过；连续物理解释仍服从 M0 blockers |
| I3 | 构造 next-level eigenvalue correction，并与高分辨率 reference 比较 effectivity | 当前 I2 matched roots；公共 trace transport | 至少三个匹配 levels、reference uncertainty、predicted/actual shift 和 effectivity 可复现；没有把未证明 saturation 冒充 certification |
| I4 | 用独立参数、mode 或离散路径检验结论的可迁移性 | 当前 I3 representative case | 至少一个独立 real case、MATLAB parity 和独立高分辨率 reference 完成 |

## 当前边界

I1.1 与 I1.2 均以 `PASS WITH CONDITIONS` 通过。I1.3 已在同一模型上完成 $M=48$
参数连续性、粗细层 transport、$M=12\to24\to48$ 分层筛查和独立 width-driven 局部加密。
新版局部实验在 15 层、33 个唯一 $k$ 点与 167 个 hard gates 全部通过后，以
$7.6294\times10^{-7}$ 的最终区间宽度正常结束，记录 fixed-$M=48$ 离散候选
$k=1.8327703475952146$、$q=8.3200886232193094\times10^{-8}$。coarse/fine 最小位置
全程无漂移；最终三层仍明显变化，因此没有 $10^{-3}$ 平台。历史 v1 的 prominence
design-gate stop 保留为设计负例，OP-CI1-7 已由 v2 关闭。

graph-basis mutation 的有限差分门仍失败，因此 production derivative、derivative-based Newton
和 correction 不可用；production separation 也继续作为更强 perturbation claim 的
`IMPORTANT CAVEAT`。I1.4 已在 $r_0=3.8146972647368216\times10^{-7}$ 的冻结圆盘上完成
sampled anchored branch、fixed chart/rank、factor/QZ/graph、loop closure、full-$F$ CR 和
负例门。V4 所有 positive gates 通过，V5 以非对称 assembly oracle 闭合唯一因物理对称而
不可辨识的 transmission swap，最终为 `PASS WITH CONDITIONS`。

I2.1 随后在同一 fine、$M=48$ 对象和冻结圆盘上完成 Method 1B factor-aware count。
proxy、BIE、64 个 resolvents、fixed-section 和 Dirichlet factors 的嵌套 winding 均为 zero，
主 $A_{\mathrm{def}}^D$ 的 32/64 winding 均为 one；最终为 `PASS WITH CONDITIONS`。这只
隔离出一个按代数重数计的 finite-dimensional zero，尚未给出位置、导数单根、非零物理场、
continuous eigenvalue 或 estimator。下一门是另行设计 I2.2 root solve 与最低伪根排除。
