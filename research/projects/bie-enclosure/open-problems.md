# 未解决问题

| ID | 类别 | 问题 | 影响范围 | 最省的下一步检查 | 状态 |
|---|---|---|---|---|---|
| OP-BE-1 | `BLOCKER` | 草稿只有单一周期背景，且假定场精确准周期；实际左右引线不同，MFS 场在接缝上只近似准周期。 | 谱距离定理能否用于实际场。 | 报告审查通过（0 blocker，R-1 已改）；草稿第 2、5 节已改，文字待全文送审。 | RESOLVED（理论） |
| OP-BE-2 | `BLOCKER` | $\varepsilon$、$U$、$C$ 目前都是浮点估计，没有可靠的 $\overline\varepsilon$、$\underline U$、$\overline C$。 | 结论能否称为可靠上界。 | budget-v1 给出预算余量；之后再设计可靠评价。 | OPEN |
| OP-BE-3 | `IMPORTANT CAVEAT` | 接合墙法向跳跃平方在 768→1536 点下降约 60%，原因不明。 | 768 点的 $\varepsilon$ 是否代表固定场。 | budget-v1 (d)：分别固定源节点和评价节点。 | OPEN |
| OP-BE-4 | `IMPORTANT CAVEAT` | 带隙证书：需要两条引线在全部 Bloch 参数上的能带上下确界（报告 T1.4）。 | 区间外谱点的解释（不影响谱距离界本身）。 | 设计证书，复用 FEM 线的 (A) 经验。 | OPEN |
| OP-BE-5 | `IMPORTANT CAVEAT` | 可靠评价的成本未知；需要证明 BIE 在成本或宽度上优于 FEM 线（宽 $4.46\times10^{-9}$，约 12 分钟，另加 (H) 约 55 分钟）。 | 课题是否继续。 | budget-v1 之后估算可靠评价的成本。 | OPEN |
