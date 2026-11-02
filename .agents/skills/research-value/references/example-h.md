# Example: checking the isolation assumption (H), 2026-11-02

Sources: `research/explorations/numerical-directions/README.md` (目标,
修订后的判断, stages 3c, 3d, 4a, 4b, 下一步 items 1–2),
`isolation-survey.md` (opening summary), `dtn-inertia-count.md`, and the
user's messages of 2026-11-02.

Earlier drafts of this card made three errors, all corrected below.
- They called the step "optional", because a conditional interval and a
  wide interval would still be delivered. That silently lowered the root
  requirements.
- They then called it "required for the root", because no known
  second-order method avoids (H). That upgraded "none found" to
  "unavoidable": the root never asked for uniqueness, and the BIE route
  does not need it.
- They summarized the survey as "no method checks isolation in internal
  gaps". The survey says published isolation and count results exist;
  what is missing is a numerical certificate usable for this 2D model.

## Brief mode (answer in chat)

User: "为什么要证明 (H) 的计数定理？"

| 原目标 | 本项作用 | 最近对照 | 预期收益 | 最小检查 | 继续或停止的条件 |
|---|---|---|---|---|---|
| 有保证且紧的含特征值区间，精度约 $5\times10^{-9}$ 量级；内部谱隙中的导模；不要求唯一性；成本未指定，暂用已有阶段预算 | 只对直接 FEM + Goerisch 必需：它的二阶区间以 (H) 为前提。计数定理是认证 (H) 的一条候选路线，不是唯一路线 | BIE 路线不需要 (H)，是需要比较的候选路线，它是否满足全部要求待复查；已读文献中没有可直接用于本二维模型的数值认证流程 | 为认证 (H) 提供具体判据：条件性定理已证明，部分验证方法尚待建立 | 两端矩阵负特征值个数之差，预测为 1；表面态扫描，预测窗口内没有接近奇异的点。两者都只是数值依据 | 先复查 BIE 是否已有充分理由退出主线：若没有，先比较两条路线；若有，且检查符合预测，就交给用户决定是否投入"排除表面态" |

## Full card (excerpt)

**最终目标**
| 要求 | 内容 | 出处 |
|---|---|---|
| 精度 | 紧：有效性指数在加密时有界；约 $5\times10^{-9}$ 量级 | README"修订后的判断"第 1 条；量级是用户在对话中提出的，参照此前 BIE 估计的量级 |
| 保证形式 | 有保证的含特征值区间；不要求唯一性 | README"修订后的判断"第 1 条、"下一步"第 2 条 |
| 适用范围 | 本仓库模型中、内部谱隙里的线缺陷导模 | README"目标" |
| 成本 | 未指定，暂用已有阶段预算 | 当前阶段配置 |

**本项作用**
- 必需性：只对当前方法（直接 FEM + Goerisch）必需。而且当前方法需要的是 (H) 本身，计数定理只是认证 (H) 的一条候选路线。
- 替代路线：BIE 路线不需要 (H)（用户说明）。它的保证形式、适用范围和成本是否满足全部要求，尚待核对。README"下一步"第 1 条显示，是否改用直接 FEM 路线仍"待用户决定"。
- 当前方法比 BIE 好在哪里：待复查。复查要做两件事：
  1. 还原记录：BIE 是否已被明确放弃，理由是什么，这些理由在当前目标下是否仍然成立；
  2. 决定是否需要补算成本。两条路线没有共同的上游计算，所以成本边界要从问题模型开始。
- 已有的成本比较不能代替：
  - "P3 用不到 R 一半时间"是 P3 和 R 之间的比较，不是和 BIE 的比较；
  - FEM 候选解是双方共用的，可以放在边界外；但 R 的源矩准备只有 R 用，必须算在 R 内，而现有计时没有包含它（README 第 3c 阶段）。

**预期收益**
| 主张 | 类别 | 数字 | 和谁比 | 控制变量是否一致 | 方法自身的差异 | 证据 | 文献里是否已有 |
|---|---|---|---|---|---|---|---|
| 为认证 (H) 提供具体判据 | 保证更强 | 希望保持 $4.70\times10^{-9}$ 的宽度；认证后的实际宽度未知 | 命题 1 只假设 (H) | 一致（同一算例、同一目标量） | (H) 换成 (P)、端点 DtN 误差、投影常数 | 只有证明 | 已读文献中没有可直接用于本模型的数值认证流程 |
| 认证本模型中的孤立性 | 适用范围更大 | — | Brown 等（精确计数）；Nagatou–Plum–Nakao（排除） | — | 前者要求缺陷足够弱且为正、背景只有一种周期结构；后者只处理一维问题，只排除、不计数 | 只有证明；本模型的完整算例还没有 | 见左栏；目前只能写"超出了这两项工作的上述限制"，并以 (P) 等条件为前提 |

**结论有多强**
- 结论形式：不等式。
- 所需的量：
  - 端点 DtN 误差、投影常数，现在都算不出来；
  - "没有表面态"没有方法检查；
  - 三项都已转入前提条件表。
- 证明状态：定理 1、2 已证明并审查，审查后的修改尚未复审。
- 舍入误差：未考虑。

在定理的条件下，界成立。要说"这个算例上界成立"，还要检查下表的条件；目前没有一条是"已验证"。

**前提条件**
| 条件 | 类型 | 典型实例是否满足 | 能否检查及目前状态 | 不成立时的后果 |
|---|---|---|---|---|
| (H)（做本项之前） | 实例条件 | 窗口够小时通常满足（推测） | 没有方法 | 悄悄出错 |
| (P)：能带间隙部分 | 实例条件 | 依能带而定 | 有数值证据 | 计数结论失效 |
| (P)：没有表面态 | 实例条件 | 未知，与截线位置有关 | 没有方法 | 计数结论失效 |
| 端点 DtN 误差足够小 | 实例条件 | 未知 | 没有可计算的界 | 计数结论失效 |
| 投影常数的界 | 实例条件 | 未知 | 原则上可以验证 | 计数结论失效 |

**最小检查的边界**：两项检查都只是继续研究的数值依据，不能代替连续层面的计数，也不能代替排除表面态。用原始矩阵算出的惯性，也不等于带误差修正的两个认证矩阵（`dtn-inertia-count.md` 第 5 节"与现有计算的关系"）。

**建议**：
1. 复查 BIE 的主线地位。先还原已有结果和决策依据，再判断哪些缺项会改变决定。
2. 做两项最小检查。
3. 交给用户决定，是否投入"排除表面态"这个未解决的问题。

**降级方案**（目标的一部分明显难以实现，因此列出）
| 方案 | 放弃了哪项要求 | 还能交付什么 |
|---|---|---|
| (H) 写成明确假设，附上检查的数值证据 | 保证形式 | 二阶区间，在所列条件下成立 |
| 只交付命题 5 | 精度 | 一阶区间 $1.00\times10^{-4}$ |

BIE 不是降级方案，而是待复查的候选路线。它是否满足全部要求，尚待核对。
