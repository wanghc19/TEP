# I9 符号与代码映射

本表局部服务于 [[research/projects/eig-apost/implementation/i9/design-9-1a|I9.1 设计]]。
不修改 I8 记号，不定义谱距离估计量。

| 记号 | 代码语义 | 说明 |
|---|---|---|
| $k,\beta$ | 频率参数、固定准周期参数 | $\beta=0.5$；$k$ 不从旧结果读取 |
| $a_-,a_+$ | negative/positive lead 径向变形 | $0.12,0.20$；同一全局朝向 |
| $r,r',r''$ | 解析径向函数及导数 | 生成六行 $[x;x';x'';y;y';y'']$ |
| $R_L,T_{RL},T_{LR},R_R$ | 每侧独立散射块 | $L/R$ 是胞元壁，不是正/负半轴 |
| $A_s,B_s$ | 第 $s$ 侧 Bloch 铅笔 | $A_sv=\lambda B_sv$ 沿全局 $+x$ 推进 |
| $\alpha,\vartheta$ | QZ 齐次对角对 | 不把零/无穷单独判成 $0/0$ 不定 |
| $d_j$ | normalized circle distance | $||\alpha|/h-|\vartheta|/h|$，$h=\operatorname{hypot}(|\alpha|,|\vartheta|)$ |
| $\tau_{\rm in},\tau_{\rm out}$ | 传播证据/不确定环带阈值 | 工程资格标准，不是误差界 |
| $Z_-,Z_+$ | 向负/正无穷衰减子空间 | 分别来自 $(B_-,A_-)$ 与 $(A_+,B_+)$ 稳定空间 |
| $\Lambda_-,\Lambda_+$ | 中心端口外法向 DtN | 负号与正号分别对应中心的 $-x,+x$ 外法向 |
| $A_{\rm def},A_{\rm phys}$ | 未加权/既有物理权重匹配阵 | 两者均 $194\times194$；四指标必须同点同阵 |
| `resolution_id` | coarse/fine 空间档位 | 与 `round` 细化轮次不同 |
| $W$ | 当前整轮末点减首点 | 正常完成门 $W\le2\times10^{-14}$ |
| $w$ | winner 实际左右邻点距离 | 不是 $W$，也不是单侧步长 |
| projected gap | 每侧固定 $\beta$ 的数值无近圆模态区间 | 对连续谱不作认证；截断端与分类不确定端单列 |
| common gap | 两侧已缓冲可用区间交集 | 每个实际候选点还需 fine 两侧重分类 |

## 实际接口和原始记录

唯一配置入口 `search_i9_config.m`。左右形状字段为 `model.a_negative/a_positive`；节点数分别为
`resolutions.(resolution_id).negative_ntot/positive_ntot`，中心为 `center_ntot`。
`qualification.inner_floor/outer_floor` 与残差因子控制上述环带；`gap.edge_width/buffer` 控制搜索边缘，
`gap.cache_bytes` 限制大型 lead cache；这里仅映射，不再建立第二份参数定义。

`search_i9_physics('leads',k,resolution_id,config)` 返回独立 `negative/positive` 散射对象、各自诊断及
`common_gap`。`search_i9_physics('match',k,resolution_id,config,lead_data)` 消费同点同档 lead 数据，
只构造中心和匹配阵；`equal_validation` 是一次相同侧配置的退化检查，不参与选点。
`search_i9_classify(alpha,theta,residual,K,config)` 只分类给定齐次数据，不构造网格、不强选子空间。

| 原始路径/字段 | 内容 |
|---|---|
| `state.gap_exploration` / `gap_extension` | 本次探索网格、左右逐点总分类、lead record 引用 |
| `state.gap_sides.negative/positive` | 每侧连续段、gap/excluded 端点及端点类型、safe bounds |
| `state.common_gaps` | 两侧来源段编号、缓冲后交集、升档检查/搜索状态 |
| `state.representative_checks` | 三代表点的 coarse/fine lead record 引用与散射矩阵差 |
| `state.lead_log.records` | 每次新构造的 `k_hex`、档位、左右齐次分类、BIE 残差、FMM 调用和时间 |
| `state.lead_log.requests` | lead 请求、`COMPUTED/CACHE_HIT`、record 引用与 bypass 标记 |
| `state.lead_log.cache_peak_bytes/evictions` | 有界缓存观测与淘汰数；不是进程 RSS |
| `state.points/requests` | 匹配点四指标、状态、耗时、精确点键、缓存命中和调用记录 |
| `state.intervals/history/coarse_dips` | source、`gap_id`、分支、实际轮网格、winner、$W$ 和停止原因 |
| `state.candidates/confirmations` | 正常/未解决末端记录，bypass 复算证据与指标差 |

lead 与匹配的 exact cache 键均以 `jsonencode(config) + resolution_id + num2hex(k)` 组成，
不以十进制截断合并点；lead cache 还单独记录淘汰与重构。父阶段时间包含其内部 lead/FMM 调用，
不能把 callback 或 lead 子计时重复加到完整匹配点时间。
`equal_validation` 在普通调度外另构造两套 lead 和一个中心；报告总构造数时单列补入。
其嵌套 callback ledger 不保留外层中心回调，完整验证时间仍由外层 `seconds` 计量。

## 中心缩放对照的局部记号

[[research/projects/eig-apost/implementation/i9/design-9-1a|设计第 8 节]] 保留原 `attempt-1`，追加
`attempt-2`。`model.star_scale` 是公共 star 结果以外的统一六行尺度 $s$；公共函数内部 $0.2$
是原始形状定义的一部分，两者不可混淆。基线 $s=\sqrt{0.04/0.0618}$，本次对照 $s=1$。

| 量 | 代码/数值口径 |
|---|---|
| $C_0=[x_0;x_0';x_0'';y_0;y_0';y_0'']$ | 公共 `geom.construct_cont(...,'star',...)` 原输出，已包含内部 $0.2$ |
| $C=sC_0$ | 中心六行统一外层缩放；本次 $s=1$ |
| 中心面积 | $0.0618\pi s^2$；不使用 lead 的 $\pi R^2$ 作为中心面积目标 |
| `geometry.center_scale` | 本次实际外层 $s$ |
| `geometry.center_position_envelope` | $[0.36,0.26]s$，位置绝对值包络，不是两分量实际同时达到的极值 |
| `geometry.center_expected_area` / `center_area` | 派生解析目标与实际周期采样面积，分开保留 |
| `geometry.center_minimum_speed` / `center_wall_clearance` / `center_vertical_clearance` | 当前采样最小速度、左右壁距、上下周期壁距 |
| lead 面积 | 每侧仍为 $0.04\pi$，与中心对照无关 |
| `attempt-1` / `attempt-2` | 两次独立完整科学运行，后者只改变中心外层尺度，不跨 attempt 取缓存 |

这组符号只解释明确授权的模型参数对照，不新增谱距离符号或评价配置。
独审脚本的 `--expected-star-scale` 是显式审查预期（本次为 1），不影响 MATLAB 科学参数或搜索。
审查据此独立重建中心六行、面积和包络；不能把审查参数当作第二份数值运行配置。
