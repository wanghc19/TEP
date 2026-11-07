# 红队检查（Adversarial Verification）

对本仓库任一数值路线（BIE、FEM＋DtN 等）做对抗性检查：构造极端参数、几何或
人为误差，检查方法给出的区间或上界是否仍正确，失效时是否安全（停止、拒绝输入
或区间变宽），而不是给出错误结果。规则见 [AGENTS.md](AGENTS.md)。

## 目录

```
redteam/
  AGENTS.md                 新检查的规则
  <topic>-vN/               一次检查一个目录；运行输出在 output/run-NNN/（不纳入 Git）
  tmp/                      临时输出，按任务分子目录（不纳入 Git）
  archive/                  历史检查，只读
```

## 检查列表

| 目录 | 内容 | 状态 |
| --- | --- | --- |
| [perturb-v1/](perturb-v1/README.md) | 对 BIE 例 1 的候选故意加误差（偏移 $k$、给密度或源系数加噪声、在偏移后的 $k$ 处重解），看 verify 给出的区间是否仍包含特征值 | 11 个扰动都在给出区间前停止：9 个因 verify 的十进制外向舍入缺陷（`assemble.py` 的 `directed()`），2 个因迹常数上限检查；没有错误区间，包含性未决。诊断半径 $R/\Delta\approx16$–$18$ |
| [archive/eig-apost-2026-10/](archive/eig-apost-2026-10/README.md) | eig-apost 时期 BIE 与 FEM＋DtN 两条路线的对照检查（2026-10-28，原在 epost 工作区） | 归档 |

归档目录于 2026-11-07 从 `redteam/` 顶层整体移入，内容未改，只把 Obsidian
链接改为新路径。旧规则文件改名为 `rules-2026-10.md`，不再约束新检查。其中
反引号内的路径、运行命令和 JSON 记录保持原样，仍指旧位置（`redteam/...` 或
epost 工作区）；复现时把 `redteam/` 换成 `redteam/archive/eig-apost-2026-10/`。
