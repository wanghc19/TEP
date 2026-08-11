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
| I1 | 把连续 DtN/BIE pencil 变成可审计的离散 $A_{\mathrm{def}}(k)$，并完成 half-guide graph/DtN、导数、解析 chart 和 locator readiness | 连续 $\mathcal F(k)$；合格 one-cell blocks；固定 Fourier trace space；ordered-QZ 分离与 chart policy | 组装 oracle、QZ/graph/DtN、$A_{\mathrm{def}}'$、平衡不变性、实际 trace 尾部和小复圆盘 readiness 全部通过；无当前 I1 blocker |
| I2 | 隔离并求出第一个真实离散 guided root，验证 simple-root 条件并跨相邻 levels 匹配 | 当前 I1 exit | count-one contour、收敛 root、非零左右导数配对和跨层 mode matching 通过 |
| I3 | 构造 next-level eigenvalue correction，并与高分辨率 reference 比较 effectivity | 当前 I2 matched roots；公共 trace transport | 至少三个匹配 levels、reference uncertainty、predicted/actual shift 和 effectivity 可复现；没有把未证明 saturation 冒充 certification |
| I4 | 用独立参数、mode 或离散路径检验结论的可迁移性 | 当前 I3 representative case | 至少一个独立 real case、MATLAB parity 和独立高分辨率 reference 完成 |

## 当前边界

当前 I1 离散理论设计已以 `PASS WITH CONDITIONS` 通过两项独立审查。下一里程碑只允许在
`test/` 新目录组装 test-local static oracle；不自动授权 DtN wall experiment、locator、contour 或 root isolation。
这些权限必须按 I1 内部门逐项恢复。
