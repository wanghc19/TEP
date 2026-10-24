# I9 符号与代码映射

本表局部服务于 [[research/projects/eig-apost/implementation/i9/design-9-1a|I9.1 设计]] 与
[[research/projects/eig-apost/implementation/i9/design-9-2a|I9.2 谱距离数值估计]] 和
[[research/projects/eig-apost/implementation/i9/design-9-3a|I9.3 FEM candidate 交付]]。
不修改 I8 记号；I9.1 历史局部字段保留，I9.2 谱距离与 I9.3 FEM 字段分别列于后文。

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

## 中心材料对照的局部记号

[[research/projects/eig-apost/implementation/i9/design-9-1a|设计第 9 节]] 的 `attempt-3` 以
`attempt-2` 为主基线，唯一科学变化为 `model.rho_center: 2→4`；外层尺度仍为1。

| 量 | 实际代码语义 |
|---|---|
| $\rho_c$ / `model.rho_center` | 此处的中心相对介电常数，基线2、本次4；不是折射率 |
| $n_c=\sqrt{\rho_c}$ | 中心折射率，基线 $\sqrt2$、本次2 |
| $k_{\rm int}=\sqrt{\rho_c}\,k$ | `LOCAL_cellmap` 传入 `bloch.construct_S` 的内部波数，本次 $2k$ |
| `cellmap.rho/kext/kint` | 本次补充保存的实际材料和波数调用证据；中心必须为4、$k$、$2k$，两侧仍为17、$k$、$\sqrt{17}k$ |
| `model.star_scale` | 本次仍为1，公共star内部0.2保持，不随材料改变 |
| `attempt-3` | 材料对照的独立完整运行，不载入基线计算状态；旧结果仅在结束后比较 |

代码中的材料字段不表示 BIE 的未知密度。physical density 的坐标与缩放约定仍由原 `construct_S` 保持，
不能因为 `rho_center` 改变而额外缩放未知量或匹配指标。
`--expected-rho-center` 为独审显式预期（本次4），不进入 MATLAB 科学配置；独审可据保存的
`center.rho/kext/kint` 核对实际构场输入。`budget_started_utc` 记录科学预算起点，后续批次沿用，
从而将批间等待纳入同一个40分钟墙钟；它不是数值参数。

`search_i9_diagnose(output_dir,k,resolution_id)` 是显式单点操作性诊断临时入口，现归档于
`test/i9/search-v1/output/attempt-3/diagnose-01/`，不属于从零搜索的运行依赖。它复用同一配置及
`leads/match` 路径，保存 `diagnostic` 中的配置、点/档位、两侧分类、耗时和成功点或异常正文；
不参与搜索选点。失败匹配点的 `error_stack/error_report`、`lead_log.failures` 的 `stack/report`
保留断言触发现场，不是新的科学量或分类规则。


## I9.2 固定场谱距离数值估计

配置入口属于新 `test/i9/estimate-v1/`，不从 I9.1 结果加载配置或场。本节只描述数学语义，
实际函数/字段在实现完成后核对。

| 量 | 数学/实现语义 |
|---|---|
| $k_0$ | 显式字面量 `1.5584378941820909`，固定不重定位 |
| $\mu_{\rm num}$ | 普通双精度 $k_0k_0$ |
| $q$ | 本次 $A_{\rm phys}$ 的列权回变换、单位范数与相位锚定匹配向量 |
| $P_+,P_-$ | 分别由正侧正向铅笔、负侧逆向铅笔构造的向无穷推进矩阵 |
| $G_+,G_-$ | $[Z_{+,1};Z_{+,2}P_+]$ 与 $[Z_{-,1}P_-;Z_{-,2}]$，各侧独立 |
| $G_sP_s^nc_s$ | 该侧第 $n$ 个胞元的入射状态；其密度用该侧自己的 $H$ 映射 |
| $E_v,E_n$ | 同场完整值/普通法向跳跃平方和，分中心材料、两侧材料、接合墙、内部墙及各自尾项 |
| $\varepsilon_{\rm num}$ | $\sqrt{E_n+E_v/d^2}$；不是 $R_{\rm num}$ |
| $\kappa_*,\theta$ | 三条真实曲线的全局采样最大绝对曲率及 $1-h\kappa_*$，包括直墙曲率0 |
| $C_{\rm num}$ | 当前几何、$\rho_{\min}=1$、$\rho_{\max}=17$、$\mu_{\rm num}$ 的 sampled-collar 迹常数公式值 |
| $U_{\rm num}$ | 冻结中心场在背景盘 $(0,3/8)$、半径 $1/16$ 上32×64积分得到的局部质量范数，不是全波导质量 |
| $Q_{\rm num}$ | $C_{\rm num}\varepsilon_{\rm num}$ |
| $D_{\rm num}$ | $U_{\rm num}-Q_{\rm num}$，必须为正 |
| $R_{\rm num}$ | $2\mu_{\rm num}Q_{\rm num}/D_{\rm num}$；仅 `UNCERTIFIED_RNUM` |
| 上下周期 seam | exact-QP 数学场理论值为0；768点相位对齐 value/同向 $y$ 导数差为另存的数值一致性诊断 |
| observed tail | 每侧、每种平方项分别用下一项和末项比率形成几何尾数值候选；不是可靠无限尾界 |

768材料节点只对512/256/256构场所得密度插值；“节点数”须分构场、后处理、几何采样及物理目标/
源—目标配对数。FMM callback 只替换光滑 proxy 势/梯度/Hessian，自由空间、奇异核、Kress、
跳跃项与密度坐标约定保持。上下周期诊断不另加入 $E_v,E_n$，以保持已声明的 exact-QP raw 场
和材料/纵向墙 collar 覆盖公式；不能把诊断残差小写成 exact-kernel 误差认证。

I9.2 的实际入口为 `estimate_i9_numeric()`，配置为 `estimate_i9_config()`；主输出
`result.mu_num/C_num/epsilon_num/U_num/Q_num/denominator/R_num` 逐一对应上表。
`evidence.base.center/negative/positive` 保存本次三套独立胞元，`base.matching` 保存匹配矩阵，
`base.q`、`center_density`、`lead_plus/lead_minus` 及 `propagation` 固定场身份。
`center_action/negative_action/positive_action` 是768节点完整材料行；
`negative_sum/positive_sum` 各有自己的有限前缀和观察尾。`walls` 是纵向墙账目，
`periodic` 是不计入主跳跃能量的上下周期一致性账目，`mass` 保存背景盘样本。
内层 `proxy_calls` 记录 FMM 子调用；外层 `timing` 为互斥阶段，不能把两者相加。

## I9.3 FEM candidate 与历史交付耗时

本节对应 [[research/projects/eig-apost/implementation/i9/design-9-3a|I9.3设计]]，不修改I9.1的匹配阵定义，
也不把FEM代数残差当作I9.2谱距离。唯一当前运行入口在 `test/i9/compare-v1/`。

| 量 | 数学/实现语义 |
|---|---|
| $\Omega_N$ | 截断条带 $[-N-1/2,N+1/2]\times[-1/2,1/2]$，正式 $N=6$ |
| $h,n_\Gamma$ | 基准网格尺度 $1/12$，每界面参数段数80；不是I9.1的BIE节点数 |
| $F_T$ | 六节点P2等参几何映射，界面端点和中点取解析参数位置 |
| $A,B$ | FEM梯度刚度、$\rho$加权质量阵；与BIE的 $A_{\rm def},A_{\rm phys}$ 无关 |
| $P$ | 上下相位 $e^{\mathrm i\beta d}$ 和左右Dirichlet的延拓矩阵 |
| $A_r=P^*AP,B_r=P^*BP$ | 约束后的广义Hermitian特征值问题 |
| $\mu,k$ | FEM广义特征值和其正平方根；shift只按给定 $\mu$ 窗口计算 |
| $\eta_{\rm alg}$ | $\|A_rv-\mu B_rv\|_2/(\|A_rv\|_2+|\mu|\|B_rv\|_2)$，代数残差，不是连续误差 |
| $m_S$ | 区域 $S$ 的 $\rho|Pv|^2$ 积分除以整个有限条带质量 |
| $m_{\rm center},m_{\rm core},m_{\rm ends}$ | 中心胞元、中心三胞元、两端各末两胞元质量比例；门为0.15、0.60、0.02 |
| 质量overlap | $|v_i^*B_rv_j|/\sqrt{(v_i^*B_rv_i)(v_j^*B_rv_j)}$；与频率差联合用于去重 |
| $T_{\rm FMM,stages}$ | 历史coarse+fine+完整确认阶段和553.8623668749998秒，不含gap，不是反事实从零已知窗口全成本 |
| FEM/FMM耗时比 | 本轮冻结FEM配置与历史阶段和的观察比；非同时、非同精度、非误差比较 |

FEM质量分数用于模式局域性筛选，区别于I9.2背景圆盘局部质量范数 $U_{\rm num}$。
有限端点Dirichlet不是负/正半无穷DtN；本轮不将两者等同，也不由频率接近证明同一模态。

I9.3实际配置为 `fem_i9_config('formal')`，入口 `fem_i9_run(output_dir,'formal')`。
`mesh.triangle_p2/p2_points/interface_parameters/material/cell_id` 固定曲边单元与分区；
`forms.stiffness_full/mass_full/mass_cells` 保存全空间及各胞元质量账目，`constraint.prolongation` 为 $P$，
`A/B` 为约束后矩阵。`solve_permutation` 仅是求解时数学等价AMD坐标排序，保存向量已回到原始约束坐标。
`eigenvalues/eigenvectors/source_shift/solver_flags/solve_records` 保存全部36个返回记录；
`cell_mass/overlaps/modes` 为同一组质量归一向量的区域分数、重叠与交付判据。
`modes.duplicate_of` 指向最低残差去重代表；`candidate` 不使用历史频率。
`timings.mesh_seconds/assembly_constraints_seconds/eigensolve_seconds/delivery_seconds` 为互斥算法四段，
`algorithm_seconds` 是其和，`save_export_seconds` 及进程墙钟另列。

### I9.3 续作：固定FEM频率的BIE重构场

本节对应 [[research/projects/eig-apost/implementation/i9/design-9-3a|设计第8节]]；
不将前述FEM向量当作跳跃评价输入，不沿用它的质量归一化。

| 量/字段 | 本轮语义 |
|---|---|
| `reconstruct_i93_config().k0` | 显式固定1.5584630910866906，仅继承FEM交付频率 |
| `mu_num` | 此k的实际双精度乘积，不读取FEM的特征值字段 |
| `evidence.base.q`、`center_density` | 在该k从零BIE匹配后归一化并冻结的向量/物理密度，非FEM原生场 |
| `propagation.Gminus/Pminus/cminus`、`Gplus/Pplus/cplus` | 两侧自身负向/正向衰减传播及状态 |
| `components`、`periodic` | 完整材料/纵墙有限与尾项；周期理论零及数值诊断分开，沿用I9.2语义 |
| `C_num/epsilon_num/U_num/Q_num/denominator/R_num` | 同一重构场及I9.2公式的数值量；U仍为上方背景盘局部质量范数 |
| `MAIN_AGENT_SELF_CHECK_ONLY` | 本轮自检身份，不能继承前文FEM独审或I9.2独审为本轮审查 |

`reconstruct_i93` 从零生成场，`run_reconstruct_i93` 只导出；本目录 `run_fem.py --entry reconstruct`
复用资源监控并仅调用重构入口，默认 `--entry fem` 仍保持既有FEM入口。
本轮输出身份 `attempt-1/reconstruct-01` 与原FEM `run-02` 不同，不覆盖旧结果。

## I9.4 固定原生 FEM 场的显式 RT2 通量

本节由 [[research/projects/eig-apost/implementation/i9/design-9-4a|I9.4设计]] 和
[[research/projects/eig-apost/phase3-analysis/fem-bound/theory|FEM-bound Revision B.1]] 支配。
复用 I9.3 `run-02` 的原生 reduced vector 和曲边网格；不读取随后BIE重构场。
这里的全场质量和弱残差公式不同于 I9.2/I9.3 BIE 的局部盘质量与跳跃常数。

| 量 | 本轮数学/数值语义 |
|---|---|
| $k_h,\mu_h,s$ | 固定 `1.5584630910866906`，$\mu_h=k_hk_h$，正移位 $s=\mu_h$ |
| $u$ | 保存的自由系数配合上下相位 $e^{\mathrm{i}\beta d}$ 重建、左右零延拓的同一原生P2函数 |
| $\rho_h,\rho$ | 曲边网格材料标签、原解析几何材料；只以 $\rho$ 计算主质量与体缺陷 |
| $\widehat p,p$ | 参考RT2和经 $p\circ F=J\widehat p/\det J$ 推前的实际通量 |
| $p_K^0,p^w$ | 局部15矩插值通量、一次共享边/准周期边平均后的显式相容通量 |
| $z_{E,m}$ | 固定全局法向/参数的第 $m=0,1,2$ 个Legendre通量矩 |
| $\epsilon_{K,E},\kappa_{K,E}$ | 外法向相对号、参数方向号；局部矩为 $\epsilon\kappa^mz$，两种号不可合并省略 |
| $U^2$ | $\int_{B_6}\rho|u|^2$；零延拓场的全质量，不是I9.2局部盘积分 |
| $M_s(p)^2$ | 梯度差平方加 $s^{-1}$ 倍加权体缺陷平方，直接形成小差值后积分 |
| $g_-,g_+$ | 左右人工端 $p\cdot n$ 的 $L^2$ 范数，非原生端部质量比例 |
| $C_{\rm end}$ | $(2\sqrt{s\rho_{\min}})^{-1/2}$，本轮 $\rho_{\min}=1$；不同于BIE collar常数 |
| $\eta_{\rm num}$ | $\sqrt{M_s^2}+C_{\rm end}(g_-+g_+)$ 的普通数值评价 |
| $\tau_{\rm num}$ | $\eta_{\rm num}/U_{\rm num}$ |
| $R_{\rm num}$ | $\tau_{\rm num}(\tau_{\rm num}+\sqrt{\tau_{\rm num}^2+4(\mu_h+s)})/2$；理论式(15)数值实例 |
| $a_K,b_K,r_K,l_K^0,l_K^1$ | theory式(33)局部表示、原生方程与边平均修正诊断；不自动是互斥真实误差分解 |
| $W$ | 仅本节表示theory式(34)充分界诊断，**不是** I9.1搜索整轮宽度；本轮没有搜索 |
| 未决材料包络 | 仅对未分类子片用完整 $\{1,4,17\}$ 重评；普通积分包络不等于可靠积分区间 |
| 求积阶差 | 同一固定通量、同一分片的Q8/Q10差异；不是误差上界证明 |

本轮没有全局RT2优化矩阵/求解残差；人工端矩不变且自由。
参考矩、Piola映射、边相位、场身份通过数值检查不自动建立机器认证。
判读尺度 $0.01$ 与 $10^{-4}$ 在运行前固定，不改变字段、场或参数以追求通过。

I9.4入口为 `fem_bound_i94(input_path,output_dir)`，唯一新配置 `fem_bound_i94_config()`。
`reduced/full_field/mapu` 保存同一原生场；`mapx/mapy` 是原六节点几何的二次系数。
`D` 将参考生成基系数映到15矩；`moments0/coeff0` 是局部插值，`moments/coeff` 是边平均后的实际通量。
`edge_data` 保存独立边编号、法向号、参数号、上下配对和全局矩；这些是可复核通量相容性的证据。
`element_values/element_check` 分别为Q8诊断和Q10正式逐元积分；`leaves` 保存本次真实材料分片。
`values.mass_squared/gradient_difference_squared/body_defect_weighted_squared` 对应上表三个体积分，
`values.end_squared/end_norms/C_end/eta/tau/R` 对应直接公式；
`diagnostic.material_mismatch_squared/W_squared` 是归因诊断，不重新加进主式。

具体数组口径：`moments0/moments` 为每单元15个DOF（9边矩、6内部矩），
`coeff0/coeff = moments0/moments / D.'` 为参考生成基系数，不能把两者互换。
`mapx/mapy/mapu` 的六列顺序为 $1,\xi_1,\xi_2,\xi_1^2,\xi_1\xi_2,\xi_2^2$。
`edge_data.ids/epsilon/kappa` 为单元×3，`signs` 为单元×3边×3矩，
`global_moments` 为全局边×3，`periodic` 的两列依次为bottom、top。
`leaves` 九列依次是单元编号、三个参考顶点的交错坐标、已分类材料值（0表示未决）、深度。
`element_values/element_check` 十列依次为质量平方、梯度差平方、加权体缺陷平方、
$a^2,b^2,r^2,(l^0)^2,(l^1)^2$、材料失配平方、通量平方范数。
`unknown_values/unknown_check` 五列依次为未决片质量最小值、体项最小值、质量最大值、
体项最大值、物理面积。其包络仅具有固定求积节点材料扰动语义。
`postprocess.json` 记录保存数据上的标量/分类后验，不是新的科学积分结果或机器证书。
