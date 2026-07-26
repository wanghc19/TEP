# Mainline review log

更新日期：2026-07-24。本文档只记录问题、状态和最小后续动作，不替代证明。

本次为 **preliminary review**：未修改任何 `.tex`、参考文献或数学正文，且未重新进行外部文献核验。Literature verification is incomplete.

## 定理与证明状态

| ID | 位置 | 当前状态 | 审计问题与影响 | 最小后续动作 |
|---|---|---|---|---|
| M-01 | 第 2 节 `prop:weak-strong` | background; proof present | 需检查弱 Neumann 迹、界面正则性和分片系数假设是否覆盖全文范围。 | 核对假设清单与标准迹定理，不改变结论等级。 |
| M-02 | 第 2 节 `thm:two-ended-essential-spectrum`；附录 A | established in current mainline; needs source review | 主线给出了局部紧性、Zhislin 判据和单端 Weyl 序列证明，但尚未在本轮独立核验全部外部来源及技术假设。 | 逐条核对切断交换子、端部极限算子和 Weyl 序列假设。 |
| M-03 | 第 3 节 `lem:weak-gluing`、`thm:bounded-reduction` | background/adaptation; proof present | 有界约化依赖出射关系闭性、半波导零 Cauchy 唯一性和 unique continuation。中文版增加了 Isakov 核验段，英文版未同步。 | 同步引用核验，并明确闭性和唯一性假设。 |
| M-04 | 第 3 节 `prop:relation-Bloch` | needs review | 文中明确要求把 Hohage--Soussi 结果适配到分片常数传输系数、界面条件和双分量端口迹；若适配失败，`ran Q^±` 与完整出射关系的等式会减弱。 | 建立逐假设对应表，核验 trace Riesz basis、`ker Q^±` 和稳定合成的有界下界。 |
| M-05 | 第 4 节 `thm:center-representation` | adaptation and proof target | 满射性依赖非 Wood、QP Green 正则性、互补交换波数问题和 Green 消去；`N_c` 的闭性/刻画仍关键。 | 分离“场存在”“密度唯一”“商空间同构”，逐项审计单胞专题向主线的移植。 |
| M-06 | 第 5 节 `thm:main-kernel-equivalence` | main proof target; unresolved | 证明对正则集 R3/R4 是条件性的；这些条件包含 M-04/M-05 的核心结论，不能把形式化证明步骤误记为无条件定理。 | 在 R3/R4 关闭后审计 `N_rep=ker R_g` 的识别及双向重构。 |
| M-07 | 第 5 节 `conj:Fredholm` | conjectural | 自然方形实现、参考算子可逆性、紧扰动和指标稳定性均未建立。 | 只有在主定理审计完成后研究；失败时降级为闭值域或半 Fredholm 结论。 |

## 中英文与符号一致性

| ID | 问题 | 位置 | 状态/动作 |
|---|---|---|---|
| B-01 | 出射关系英文为 `C_out^±`，中文为 `E^±`；英文场合成为 `E^±`，中文为 `F^±`，同一字母在两版承担不同角色。 | `theory.tex`/`theory-zh.tex` 宏；第 3 节 `eq:field-synthesis`, `eq:relation-stable-range` | unresolved；先决定共同语义，再成对修改两版和 `research/NOTATION.md`。 |
| B-02 | Cauchy 空间、半波导解空间、中心有界解空间与限制映射分别使用 `H_Gamma^±`/`H(Gamma^±)`、`U_out^±`/`U^±`、`B^0`/`U^0`、`Res^0`/`pi_0`。 | 第 2、3 节 | needs review；不得单独修改一版。 |
| B-03 | 中文第 3 节含完整的 Isakov unique-continuation 核验块，英文版没有对应内容。 | `research/mainline/zh/s-cauchy.tex`, R1 block | needs review；确认核验正确后同步英文，或两版统一改为同一来源说明。 |
| B-04 | `theory-zh.tex` 文件头仍指向一个已经不存在的旧 `draft` 理论文件位置，与当前物理位置不符。 | `research/mainline/theory-zh.tex` 文件头 | open；只修元数据时需同时确认真实来源版本。 |
| B-05 | 路线图限定相同左右端，主线本质谱和局域化已扩展到不同左右端；第 3--5 节是否完全支持该扩展尚未明确。 | planning scope；主线第 2--5 节 | needs review；核对所有 `±` 假设是否端点独立。 |

## 引用与路径审计

- `C-01 — source verification pending`：Fliss、Hohage--Soussi、Barnett--Greengard、Hiptmair--Moiola--Spence、Isakov 等引用的精确定理陈述、页码和假设需在正式写作前再次核验。本轮没有重新打开外部原文。
- `C-02 — resolved 2026-07-24`：主线第 2--5 节原有的旧 `attempt` 路线图路径已改为 `research/planning/muller-cauchy/` 下当前存在的简化文件名；中英文路径已同步。尚未在本轮重新编译两版。
- `C-03 — bibliography parity`：中英文主文件是否包含相同引用键和相同参考文献集合尚未做完整机械比对。

## 证明严格性待办

- [ ] 为 `prop:relation-Bloch` 建立外部定理假设到当前 PDE、界面和迹空间的逐项映射。
- [ ] 核对稳定合成映射的 Riesz 上下界、注入性和可能的 `ker Q^±`。
- [ ] 核对第 4 节 QP Green 函数、Rayleigh 重构和端口消去的函数空间收敛。
- [ ] 把互补交换波数问题的唯一可解性与 `N_c={0}` 的关系写成精确条件，而不是隐含步骤。
- [ ] 审计主定理中全局拼接、指数衰减和 `N_rep` 识别，不把正则集假设循环用作结论。
- [ ] 对 proposition、lemma、theorem、conjecture 和 status 文本做中英文逐项对照。
