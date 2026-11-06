# 决定

## 2026-11-04 新建项目（用户）

- FEM 线暂停后（[[research/projects/fem-goerisch/DECISIONS|fem-goerisch DECISIONS]] 同日条），BIE 可靠区间独立成项目 `research/projects/bie-enclosure/`，目录分类与 fem-goerisch 相同。
- ChatGPT Pro 报告移入 `theory/reliable-bound.md`，原文不改，审查写进配对的 `-review` 文件。
- 论文草稿改为被追踪的 `draft/bie-enclosure/`；`draft/tmp/bie-theory-rewrite/` 保留不动。
- 审查线程与 sol 同时派工；等审查回复后再分批提交。

## 2026-11-04 场的定义（经理建议；报告审查已确认 T2.1–T2.3）

采用报告 T2 的路线：把实际的 augmented MFS 有限表示（固定的密度、MFS 修正系数和传播系数）定义为数学场，上下接缝的准周期失配作为一类新界面计入 $\varepsilon$。理由：I9.2 的接缝跳跃平方只占 $\varepsilon^2$ 的约 0.1%，而另一条路线要给 $G_{\rm MFS}-G_{\rm QP}$ 的可计算界，更贵。

## 2026-11-05 评价用场改为胞元核 B（用户）

用户决定：若浮点增益成立就换成胞元核。cellker-v1 与 cellfit-v1 确认增益（预测全宽 $2.77\times10^{-11}$，无切换项），采用按场拟合 B（480 个固定点源）。求解仍用原回卷核，密度不重解。引线只对实际出现的状态列做评价（cellrel-v1）。

## 2026-11-05 带隙条件只引用 FEM 的 A 证书（用户）

BIE 谱距离定理不需要“窗口内只有一个特征值”（FEM 的 (H)，B、C 两步约 55 分钟），这一步不做。要把区间里的谱点解释为导模特征值，只需报告 T1.5：$[\mu-R,\mu+R]$ 在两条引线共同带隙内。FEM 的 A 证书对同一对引线证明了 $k\in[1.318,2.375]$ 为带隙，只需核对约定后引用，不另做带隙证书。剩余可靠化工作：其余四组的可靠缺陷（astra）与 $C_g$ 的几何证书（理论线程，含 A 证书约定核对）。结论比 FEM 弱一点：不说明窗口内只有这一个特征值，草稿须写明。

## 2026-11-05 候选搜索改用行列式求根（用户）

detscan-v1（经理已核对）表明 $\det A_{\rm def}(k)$ 在 I9 窗口上可用 Chebyshev 插值求根，结果与 $\sigma_{\min}$ 谷底搜索一致，求值次数从 213 降到 71（精简版预计约 36）。用户决定正式替换：带隙分类不变，粗、细搜索改为 Chebyshev 倍增插值加割线抛光，根处保留一次 $\sigma_{\min}$ 确认，异常时退回原方法。插值误差不需要证明：搜索只给候选点，可靠区间由后验证书单独给出；只有要证明"窗口内没有遗漏特征值"时才需要（已决定不做）。实现见 detsearch-v1。

## 2026-11-06 DtN 与准周期 Green 函数只改写法，不改实现（用户）

- 计算仍用端口约化矩阵 $\mathsf A(k)$（DtN 归一化）求候选：它与基无关，$\det\mathsf A(k)$ 除 Dirichlet 例外值处的极点外解析，便于 Chebyshev 求根。理论主线仍是 Cauchy 数据匹配 $\mathsf M(k)$；草稿删去重复的离散 DtN 形式 $\mathsf M_{\rm DtN}$（移入工作版），第 3.5 节改为“与 DtN 约化的关系”。改用 trace matching 行列式需要解析的子空间基（例如 Riesz 投影），这才是重写代码的真正成本，暂不做。
- 准周期层势的定理与附录 A 证明保持不变，第 4.2 节改写为“近像层势＋光滑修正＋Rayleigh 背景”（Barnett–Greengard 结构），附录 A 加推论 `cor:near-image` 说明精确场也有这一结构。评价场本来就是三近像＋480 个拟合代理点，不需要新实验。完整的 Cho–Barnett 联立求解器（会成为新实验线与 pipeline-v2）暂缓。
