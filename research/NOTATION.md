# Frozen Müller--Cauchy notation index

本文件索引 2026-07-26 冻结的 Müller--Cauchy 主线符号，不建立第二套定义。
对应文件位于 `research/archive/muller-cauchy-2026-07/`，精确冻结点为 Git 标签
`mainline-muller-cauchy-2026-07-26`。当前没有活动中的统一主线。

## 使用规则

1. 只有任务明确选择该归档或冻结标签时，才使用本索引及其对应正文。
2. 本文件只用于定位和审计冻结版本；若与归档正文冲突，以冻结标签中的正文为准。
3. 本索引不支配尚未确定的新方向，也不得被当作新 `mainline/` 的默认符号表。
4. `research/projects/` 和 `research/planning/` 可以采用任务所需的局部符号，但不得
   静默宣称它们已经成为仓库级统一记号。
5. 恢复旧路线或建立新主线时，应重新审查本索引，而不是机械继承。
6. 冻结版本的中英文冲突保留在归档的 `review-log.md`；不得通过修改归档正文擅自选边。
7. 本索引不统一理论符号与 MATLAB 变量。

## 核心符号索引

| 符号 | 简要含义 | 冻结版本位置 | 备注 |
|---|---|---|---|
| `B`, `C^0`, `W^-`, `W^+` | 无限条带、中心胞元、左右半波导 | `research/archive/muller-cauchy-2026-07/en/s-setting.tex`, `sec:functional-setting` | 中文版同标签。 |
| `Gamma^-`, `Gamma^+` | 中心胞元与半波导的端口 | `research/archive/muller-cauchy-2026-07/en/s-setting.tex`, geometry subsection | 法向量统一采用面向中心区的端口约定，详见第 3 节。 |
| `Upsilon^0`, `Upsilon^-`, `Upsilon^+` | 中心和周期端中的材料界面 | `research/archive/muller-cauchy-2026-07/en/s-setting.tex`, geometry subsection | 不要与端口 `Gamma^±` 混淆。 |
| `rho=n^2` | 冻结版本 TM 模型的材料系数 | `research/archive/muller-cauchy-2026-07/en/s-setting.tex`, `eq:material` | 不从代码变量反推其约定。 |
| `beta`, `k` | 固定准周期参数、波数参数 | `research/archive/muller-cauchy-2026-07/en/s-setting.tex`, `sec:functional-setting` | 冻结版本主要考虑实参数和严格公共带隙。 |
| `H^1_beta(B)` | 横向 `beta`-准周期能量空间 | `research/archive/muller-cauchy-2026-07/en/s-setting.tex`, `eq:H1beta` | 端口 Sobolev 空间见 `eq:port-Sobolev`。 |
| `A(beta)` | 固定 `beta` 的加权自伴算子 | `research/archive/muller-cauchy-2026-07/en/s-setting.tex`, `eq:Abeta` | 谱参数写作 `k^2`。 |
| `G(k,beta)`, `m_g(k,beta)` | 全局导模空间及几何重数 | `research/archive/muller-cauchy-2026-07/en/s-setting.tex`, `def:guided-space`, `eq:geometric-multiplicity` | `G` 是物理目标空间。 |
| `Sigma_±(beta)`, `I_beta` | 左右背景谱及选定的紧公共带隙窗口 | `research/archive/muller-cauchy-2026-07/en/s-setting.tex`, essential-spectrum subsection | 不等同于 Wood 阈值排除条件。 |
| `T^±`, `P_s^±`, `K_s^±` | 胞元平移算子、稳定 Riesz 投影、稳定系数空间 | `research/archive/muller-cauchy-2026-07/en/s-cauchy.tex`, `eq:translation-operator`--`eq:stable-coefficients` | 必须包含广义特征向量/Jordan 链。 |
| `Q^±` | 稳定系数到端口 Cauchy 迹的合成映射 | `research/archive/muller-cauchy-2026-07/en/s-cauchy.tex`, `eq:trace-synthesis` | 其值域与出射关系的等同性仍需适配审计。 |
| `Xi_beta`, `D^0` | 齐次 Rayleigh 系数空间、中心密度空间 | `research/archive/muller-cauchy-2026-07/en/s-muller.tex`, `eq:Rayleigh-space`, `eq:density-space` | `D^0` 是迹空间乘积，不是 Dirichlet 算子。 |
| `R_c`, `M`, `Z_c` | 中心重构、Müller 残差和代数核 | `research/archive/muller-cauchy-2026-07/en/s-muller.tex`, `eq:center-reconstruction-map`--`eq:center-nullspaces` | `Z_c=ker M`。 |
| `N_c`, `S_c`, `E_rep(beta)` | 中心零场表示、物理中心解空间、表示例外集合 | `research/archive/muller-cauchy-2026-07/en/s-muller.tex`, `eq:center-nullspaces` and `thm:center-representation` | `N_c={0}` 尚不能预设。 |
| `X`, `Y`, `A(k,beta)` | 耦合算子的定义域、值域与算子 | `research/archive/muller-cauchy-2026-07/en/s-muller.tex`, `def:coupled-operator` | 算子使用黑板粗体 `mathbb A`，与 `A(beta)` 区分。 |
| `R_g`, `N_rep` | 全局重构与耦合核中的零场表示空间 | `research/archive/muller-cauchy-2026-07/en/s-muller.tex`, `eq:global-reconstruction`, `eq:Nrep-definition` | 主定理使用 `ker A / N_rep`。 |
| `mathfrak R` | 主定理的正则参数集 | `research/archive/muller-cauchy-2026-07/en/s-results.tex`, section opening | 不要与实数集 `mathbb R` 混淆。 |

## 冻结版本中英文待同步符号

以下不是同义词已经裁定，而是已发现的冲突：

| 英文版 | 中文版 | 位置与状态 |
|---|---|---|
| `H_Gamma^±` | `H(Gamma^±)` | 第 2 节 `eq:Cauchy-space`；`needs review`。 |
| `U_out^±` | `U^±` | 第 3 节半波导解空间；`needs review`。 |
| `C_out^±` | `E^±` | 第 3 节出射 Cauchy 关系；`needs review`。 |
| `B^0`, `Res^0` | `U^0`, `pi_0` | 第 3 节有界中心解空间和限制映射；`needs review`。 |
| `E^±` | `F^±` | 第 3 节稳定场合成；中文的 `E^±` 已被用于出射关系，存在直接歧义。 |

## 旧符号和易混淆对应

- 路线图中的 `A_rel`、`R_global` 对应冻结版本的 `mathbb A`、`R_g`；这只是历史文件到归档正文的定位关系。
- DtN 专题中的 `(eta, xi)` 及其法向号约定是专题局部约定；若恢复旧路线，必须重新核对冻结版本第 3、4 节，不能直接替换其中定义。
- 普通 Bloch 特征向量的张成空间不能默认为冻结版本的 `K_s^±`；只有证明半单性后才能省略广义链。
- `N_c` 与 `N_rep` 都表示“重构为零场”的代数自由度，但分别属于中心表示和完整耦合，不能互换。
