# bie-enclosure：BIE 导模谱距离界论文草稿

BIE = boundary integral equation（边界积分方程）；MFS = method of fundamental solutions（基本解方法）；QP = quasi-periodic（准周期）。

由 `draft/tmp/bie-theory-rewrite/`（未追踪，保留不动）于 2026-11-04 复制而来，按 [[research/projects/bie-enclosure/theory/reliable-bound|reliable-bound]] 修改。修改处在 PDF 中以蓝色"[新改]"标注。报告中对应的结果已通过审查（[[research/projects/bie-enclosure/theory/reliable-bound-review|reliable-bound-review]]，0 个 blocker；唯一的 important caveat R-1 已在带隙证书式中改正）；草稿本身的文字尚未送审，全文送审时再去掉标注。

- `main.tex`：主文件，`s-*.tex` 为各节，`a-cellrep.tex` 为附录。
- 编译：`latexmk -xelatex main.tex`，之后 `latexmk -c main.tex`。

## 进度

| 节 | 修改内容 | 状态 |
|---|---|---|
| 1 引言 | 左右引线可以不同；记号表 $L_\pm$ | draft 完成 |
| 2 模型问题 | 两条引线 $\rho_\pm$、$L_\pm$；$D(A)=H^2_\beta$；本质谱为两谱之并（Fliss 注 2.1(2) + 证明）；谱底 $\lambda_0=b_\beta^2/\rho_{\max}$；公共谱隙与指数衰减；新增 2.4 带隙证书（Lipschitz 界） | draft 完成，对应结果已审查 |
| 3 约化 | 各侧胞元宽 $L_\pm$ 与各自的介质柱 | draft 完成 |
| 4 离散 | 增广 MFS 的说明；左右散射矩阵不同 | draft 完成 |
| 5 误差 | 场由固定的增广 MFS 表示定义（式 mfs-field）；逐片 $H^2$ 命题；(P2) 删去；接缝作为第三类界面及其跳跃；接缝领子与覆盖重数更正；新增分组迹估计命题（保留 Jacobian + 联合谱乘子）；定理证明加接缝项与分组；人工墙模态尾界标为只适用于精确准周期场；圆盘质量下界；可靠输入清单更新 | draft 完成，对应结果已审查 |
| 6 结果 | 占位，未写 | — |

蓝色"[新改]"标注共 19 处。原稿的单族迹估计（命题 5.1）保留，作为分组命题的特例。
