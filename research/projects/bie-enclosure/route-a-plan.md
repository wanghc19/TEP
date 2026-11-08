# 路线 A 探索计划：在 Wood 点也能用的 BIE 导模求解

BIE = boundary integral equation（边界积分方程）；RtR = Robin-to-Robin；FKS 2015 = Fliss–Klindworth–Schmidt 2015；FEM = 有限元；DtN = Dirichlet-to-Neumann；QP = quasi-periodic（准周期）。

2026-11-07 起草。用户决定第一版论文 `draft/bie-solver/` 按定位 B 写：Wood 点写成局限，用回退方案（在已知 Wood 线处切开窗口，排除 $|k-k_W|<\delta$ 的带）。路线 A 留到用户审第一版时，交给 Codex 探索。本文件给出任务顺序和可以直接发出的提示词。**尚未发送任何一项。**

## 进度

- done：提示词写好，放在 `tmp/codex-prompts/a1-wood-cell-v1.md`、`a2-wood-cross-v1.md`、`a3-rtr-compare-v1.md`、`a4-wood-theory.md`。
- next：用户开始审第一版后，同时发 A1（astra）和 A4（theorem-proof）。
- 开放问题：A1 失败时，路线 A 是否还有价值（见下面"停止条件"）。

## 路线 A 想多说什么

定位 B 只说：Wood 点附近的根还能算准，正好在 Wood 点上算不了，要排除一个带。路线 A 想多说一句：**两侧是不同周期引线时，固定 $\beta$ 的导模支穿过背景 Wood 点时也能用 BIE 算，而且精度不下降。**

`research/explorations/numerical-directions/wood-robust-ports.md` 的检索没有找到这种算例。已有的先例分两类：开放光栅在 Wood 点的 BIE（Barnett–Greengard 2011、Cho–Barnett 2015、Bruno–Delourme 2014、Pérez-Arancibia 等 2019），以及闭胞全纯的体能带 BIE（Pérez-Arancibia–Yin 2026）。检索范围以该文件为准，不能说"首次"。

已知的问题（`test/bie-bound/wood-probe-v1/`）：奇异出在单胞的出射表示本身。QP Green 函数 $m=0$ 项约为 $1/|\gamma_0|$。只在求解之后换坐标不够，会留下约 $1.3\times10^{-14}/t$ 的共同误差。所以单胞问题本身要用正则坐标重写。

## 任务与顺序

| 编号 | 线程 | 内容 | 依赖 | 预计 |
|---|---|---|---|---|
| A1 | astra | `wood-cell-v1`：单胞求解器。近像自由空间层势加代理源，胞壁输出取 Cauchy 数据子空间（不取映射），掠射阶用 Barnett–Greengard 2011 的常数、线性函数。只测单胞，含精确 Wood 点。 | wood-fallback-v1 完成 | 3 小时，计算约 1.5 小时 |
| A4 | theorem-proof | `wood-cauchy.md`：在 Cauchy 坐标下重证引理 A 和定理 B，跨过 Wood 点；回答截断定理能否去掉"无 Wood 点"的假设。 | 无 | 4 小时 |
| A2 | astra | `wood-cross-v1`：用 A1 的单胞组装整条求解链，算例 1 和 W3 的导模支穿过 Wood 点，用 FEM + DtN 对照。另做假根检验。 | A1 通过 | 3 小时，计算约 2 小时 |
| A3 | astra | `rtr-compare-v1`：同一单胞数据上比较加边闭合与 FKS 2015 的 RtR 闭合，含极点、Wood 点和单次求值成本。 | A2 | 3 小时，计算约 1.5 小时 |
| A4r | proof-review | 审查 A4。提示词按 `tmp/codex-prompts/port-subspace-review.md` 的格式改写；不要转述 worker 的结论。 | A4 | 2–3 小时 |

A1 与 A4 用不同线程，可以同时发。A2、A3 都在 astra 上，依次发。

## 停止条件与价值判断

| 结果 | 含义 | 下一步 |
|---|---|---|
| A1 预测 1–3 成立 | 单胞在 Wood 点正则 | 发 A2 |
| A1 在精确 Wood 点仍病态，或与旧求解器离开 Wood 点不一致 | 构造有错，或掠射阶处理不对 | 让 astra 只修一次；仍失败就停下来，交用户决定是否保持定位 B |
| A2 预测 2 成立，且与 FEM 一致 | 路线 A 的核心算例成立 | 发 A3；交用户决定第二版是否改定位 A |
| A2 精度在穿越处明显下降 | 正则单胞不够，闭合或子空间还有问题 | 对照 A4 的结论找原因 |
| A3：RtR 在所有窗口都不弱于加边闭合 | 加边闭合相对 RtR 的价值只剩"不必选 $\alpha$" | 写进论文的对照，弱化定理 B 的地位 |
| A4 证明 Cauchy 坐标下定理 B 成立 | 论文可以把 Wood 点写进定理的适用范围 | 送 A4r |

成本注意：FEM + DtN 本来就没有 Wood 奇异。路线 A 增加的是 BIE 的适用范围，而不是相对 FEM 的新优势；成本优势仍只在最高精度档（`test/bie-bound/solver-cost-v1/`）。是否值得为此改定位，由用户在看到 A2 后决定。

## 发送方法

在仓库根目录：

```sh
codex queue --thread <线程 ID> --message "$(cat tmp/codex-prompts/a1-wood-cell-v1.md)"
.agents/skills/research-manager/scripts/codex-wait.sh <线程 ID> 200 30   # 后台运行
```

线程 ID 见 `tmp/research-manager-log.md`（astra、theorem-proof、proof-review）。回复从 `~/.codex/sessions/` 下对应 rollout 文件读，只读。每份结果按 research-manager 的核查清单核查后才写进论文或状态文件。核查后在 `test/bie-bound/README.md` 加索引行。

发 A2、A3 前，检查提示词里引用的上一步目录名和结论是否与实际结果一致，按需修改。
