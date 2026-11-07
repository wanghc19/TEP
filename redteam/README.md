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
| [archive/eig-apost-2026-10/](archive/eig-apost-2026-10/README.md) | eig-apost 时期 BIE 与 FEM＋DtN 两条路线的对照检查（2026-10-28，原在 epost 工作区） | 归档 |

归档目录于 2026-11-07 从 `redteam/` 顶层整体移入，内容未改，只把 Obsidian
链接改为新路径。旧规则文件改名为 `rules-2026-10.md`，不再约束新检查。其中
反引号内的路径、运行命令和 JSON 记录保持原样，仍指旧位置（`redteam/...` 或
epost 工作区）；复现时把 `redteam/` 换成 `redteam/archive/eig-apost-2026-10/`。
