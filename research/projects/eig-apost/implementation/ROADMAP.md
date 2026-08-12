# Eigenvalue a posteriori implementation roadmap

本页只维护新路线的项目级阶段、依赖关系和退出条件。I1 内部设计、组装、DtN 验证和 locator
readiness 的具体进度统一记录在
[[research/projects/eig-apost/implementation/i1/README|current I1 guide]]；实验物理路径由
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
| I1 | 把连续 DtN/BIE pencil 变成可审计的离散 $A_{\mathrm{def}}(k)$，并完成 half-guide graph/DtN、导数、解析 chart 和 locator readiness | 连续 $\mathcal F(k)$；合格 one-cell blocks；固定 Fourier trace space；ordered-QZ stable subspace 与 chart policy | 静态组装、经验型参数连续性与 $A_{\mathrm{def}}'$、平衡不变性和小复圆盘 readiness 通过；production separation 未完成时只作 caveat，不冒充扰动认证 |
| I2 | 隔离并求出第一个真实离散 guided root，验证 simple-root 条件并跨相邻 levels 匹配 | 当前 I1 exit | count-one contour、收敛 root、非零左右导数配对和跨层 mode matching 通过 |
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

graph-basis mutation 的有限差分门仍失败，因此 production derivative、Newton 和 correction
不可用；production separation 也继续作为更强 perturbation claim 的 `IMPORTANT CAVEAT`。
I1.4 本轮未开始且未获数值执行授权。下一步若另行授权，只能先预注册 anchored complex-$k$
branch、fixed chart/rank、factor/pole ledger、CR 和实际对象负例；不得直接运行 locator、
contour 或 root isolation。具体进度和四个 I1 里程碑见 I1 guide。
