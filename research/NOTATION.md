# Current research notation

本文件只索引 `research/` 工作域内的当前理论符号，不建立第二套定义。

## 使用规则

1. `research/` 内的符号、定义和数学表述始终以 `research/mainline/` 当前内容为准。
2. 本文件只用于定位和审计；若与主线冲突，以主线正文为准并记录冲突。
3. 不从 `draft/`、`pre/`、`legacy/` 或代码推导当前研究符号。
4. `research/projects/` 和 `research/planning/` 可保留历史或局部符号，但不得覆盖主线。
5. 专题采用旧符号时只记录必要对应关系，不改写历史材料。
6. 主线引入、修改或废弃符号时，应同步更新本文件。
7. 英文版和中文版发生冲突时，必须写入 `research/mainline/review-log.md`，不得擅自选边。
8. 当前不统一理论符号与 MATLAB 变量。

## 核心符号索引

| 符号 | 简要含义 | 主线权威位置 | 备注 |
|---|---|---|---|
| `B`, `C^0`, `W^-`, `W^+` | 无限条带、中心胞元、左右半波导 | `research/mainline/en/s-setting.tex`, `sec:functional-setting` | 中文版同标签。 |
| `Gamma^-`, `Gamma^+` | 中心胞元与半波导的端口 | `research/mainline/en/s-setting.tex`, geometry subsection | 法向量统一采用面向中心区的端口约定，详见第 3 节。 |
| `Upsilon^0`, `Upsilon^-`, `Upsilon^+` | 中心和周期端中的材料界面 | `research/mainline/en/s-setting.tex`, geometry subsection | 不要与端口 `Gamma^±` 混淆。 |
| `rho=n^2` | 当前 TM 模型的材料系数 | `research/mainline/en/s-setting.tex`, `eq:material` | 不从代码变量反推其约定。 |
| `beta`, `k` | 固定准周期参数、波数参数 | `research/mainline/en/s-setting.tex`, `sec:functional-setting` | 当前主要考虑实参数和严格公共带隙。 |
| `H^1_beta(B)` | 横向 `beta`-准周期能量空间 | `research/mainline/en/s-setting.tex`, `eq:H1beta` | 端口 Sobolev 空间见 `eq:port-Sobolev`。 |
| `A(beta)` | 固定 `beta` 的加权自伴算子 | `research/mainline/en/s-setting.tex`, `eq:Abeta` | 谱参数写作 `k^2`。 |
| `G(k,beta)`, `m_g(k,beta)` | 全局导模空间及几何重数 | `research/mainline/en/s-setting.tex`, `def:guided-space`, `eq:geometric-multiplicity` | `G` 是物理目标空间。 |
| `Sigma_±(beta)`, `I_beta` | 左右背景谱及选定的紧公共带隙窗口 | `research/mainline/en/s-setting.tex`, essential-spectrum subsection | 不等同于 Wood 阈值排除条件。 |
| `T^±`, `P_s^±`, `K_s^±` | 胞元平移算子、稳定 Riesz 投影、稳定系数空间 | `research/mainline/en/s-cauchy.tex`, `eq:translation-operator`--`eq:stable-coefficients` | 必须包含广义特征向量/Jordan 链。 |
| `Q^±` | 稳定系数到端口 Cauchy 迹的合成映射 | `research/mainline/en/s-cauchy.tex`, `eq:trace-synthesis` | 其值域与出射关系的等同性仍需适配审计。 |
| `Xi_beta`, `D^0` | 齐次 Rayleigh 系数空间、中心密度空间 | `research/mainline/en/s-muller.tex`, `eq:Rayleigh-space`, `eq:density-space` | `D^0` 是迹空间乘积，不是 Dirichlet 算子。 |
| `R_c`, `M`, `Z_c` | 中心重构、Müller 残差和代数核 | `research/mainline/en/s-muller.tex`, `eq:center-reconstruction-map`--`eq:center-nullspaces` | `Z_c=ker M`。 |
| `N_c`, `S_c`, `E_rep(beta)` | 中心零场表示、物理中心解空间、表示例外集合 | `research/mainline/en/s-muller.tex`, `eq:center-nullspaces` and `thm:center-representation` | `N_c={0}` 尚不能预设。 |
| `X`, `Y`, `A(k,beta)` | 耦合算子的定义域、值域与算子 | `research/mainline/en/s-muller.tex`, `def:coupled-operator` | 算子使用黑板粗体 `mathbb A`，与 `A(beta)` 区分。 |
| `R_g`, `N_rep` | 全局重构与耦合核中的零场表示空间 | `research/mainline/en/s-muller.tex`, `eq:global-reconstruction`, `eq:Nrep-definition` | 主定理使用 `ker A / N_rep`。 |
| `mathfrak R` | 主定理的正则参数集 | `research/mainline/en/s-results.tex`, section opening | 不要与实数集 `mathbb R` 混淆。 |

## 中英文待同步符号

以下不是同义词已经裁定，而是已发现的冲突：

| 英文版 | 中文版 | 位置与状态 |
|---|---|---|
| `H_Gamma^±` | `H(Gamma^±)` | 第 2 节 `eq:Cauchy-space`；`needs review`。 |
| `U_out^±` | `U^±` | 第 3 节半波导解空间；`needs review`。 |
| `C_out^±` | `E^±` | 第 3 节出射 Cauchy 关系；`needs review`。 |
| `B^0`, `Res^0` | `U^0`, `pi_0` | 第 3 节有界中心解空间和限制映射；`needs review`。 |
| `E^±` | `F^±` | 第 3 节稳定场合成；中文的 `E^±` 已被用于出射关系，存在直接歧义。 |

## 旧符号和易混淆对应

- 路线图中的 `A_rel`、`R_global` 对应主线当前的 `mathbb A`、`R_g`；这只是历史文件到当前主线的定位关系。
- DtN 专题中的 `(eta, xi)` 及其法向号约定是专题局部约定，使用前必须重新核对主线第 3、4 节，不能直接替换主线定义。
- 普通 Bloch 特征向量的张成空间不能默认为当前 `K_s^±`；只有证明半单性后才能省略广义链。
- `N_c` 与 `N_rep` 都表示“重构为零场”的代数自由度，但分别属于中心表示和完整耦合，不能互换。
