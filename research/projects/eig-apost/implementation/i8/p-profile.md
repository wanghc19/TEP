# I8 单点评价耗时诊断设计

## 1. 问题、范围与状态

- Design ID: `I8-POINT-PROFILE-V1`
- Status: `FROZEN FOR EXECUTION`
- Numerical object: `[out,scan] = locate_i8(k,1,1)` 的 I8.1 baseline 单点评价
- Research question: 一次单点评价的时间主要花在哪里；现有证据是否足以把下一步优化重点放在 smooth proxy correction field 的局部展开
- Success criterion: 两个代表点的 warm unprofiled 计时可解释、四指标与原入口一致、主要时间可用不重复计数的账目归属，并据此给出有边界的瓶颈判断

本诊断属于 I8 内部里程碑，不建立 I9，不改变数学模型、离散空间、公式或定位结果的含义。它不重新定位候选，不运行 `check_i8`、`estimate_i8` 或完整扫描，也不实施局部展开、FMM、插值、缓存或新的求根方法。当前关于 proxy 场可能昂贵的说法只是待检验假设。诊断结果即使否定该假设也算合格交付。

权威对象依次为当前 `codex/epost` 工作树中的 [[test/i8/locate-v1/locate_i8|locate_i8]]、[[test/i8/locate-v1/README|I8.1 机器记录]]、[[research/projects/eig-apost/implementation/i8/design-8-1b|I8.1 定位设计]]、[[research/projects/eig-apost/implementation/i8/review-8-1b|I8.1 独立审查]]和本设计。历史 I8.3 的中心512／lead256 配置不进入本诊断。遗留科学限制继续集中在 [[research/projects/eig-apost/implementation/i8/README#历史基线与遗留问题|I8 问题表]]；未认证和未证明收敛不构成本诊断 blocker。

## 2. 冻结模型与代表点

两个点使用完全相同的配置：$\beta=0.5$；左右 lead 为半径 $0.2$、`epsrel=17` 的圆；中心为公共五瓣星形全部六行乘 $\sqrt{0.04/0.0618}$、`epsrel=2`；

```text
(ntot,nside,ntop,nproxy,mpw,M) = (256,160,160,80,32,48)
K = 2*M+1 = 97
```

每个 inclusion 的内部 BIE 为 $512\times512$，$A_{\rm def}$ 与 $A_{\rm phys}$ 均为 $194\times194$。中心和 lead 都调用修正后的公共 `bloch.construct_S`；不能再次施加 density scaling，也不能把已经合并的左右入射拆回逐右端求解。

代表点固定为：

| Role | $k$ | 历史证据与选择理由 |
|---|---:|---|
| candidate | `1.7562818500073463` | I8.1 run-17 的正式采样 argmin；run-18 新 MATLAB 进程单点复算四指标逐位一致 |
| ordinary local neighbor | `1.7562818560000002` | run-06 的第 5/11 点和 winner；run-07、run-08 又实际评价同一点，四指标均为 `(5.1427176954783761e-08, 8.5119588994282451e-11, 2.5434108843217626e-08, 8.9062407543503152e-09)` |

第二点与候选相差 `5.992653706155648e-09`，约为该量级处 $2.7\times10^7$ 个 binary64 ulp。它在同一局部谷底内、有跨网格的历史重复证据，同时不会把诊断建立在 run-17 几个 ulp 的不规则精细排序上。本轮不为选点追加扫描。

## 3. 最小诊断入口

先直接观察原始 `locate_i8`。若 MATLAB profiler 不能给出 lead、QZ/DtN、中心和匹配/SVD 四层互斥时间，可在 `test/i8/profile-v1/` 新建一个不同名的诊断入口。它只复制 `locate_i8` 中形成同一单点评价所必需的 `LOCAL_` helpers，在原有语句边界加 `tic/toc`，仍通过正常 MATLAB 路径调用公共 package；不得复制或遮蔽 `+kernel`、`+op`、`+bloch` 或 `+geom`。

诊断入口必须由显式 $k$ 输入驱动。模型和冻结空间参数保存在 MATLAB source 中；运行不得读取 Markdown、Git、历史 MAT/JSON/CSV 或硬编码本机路径。保存、资源监控和 profiler 导出由外层 launcher 负责。

## 4. Unprofiled 基线协议

在一个没有其他活跃 MATLAB 的新进程中串行执行：

1. 记录 MATLAB 进程 wall time；在 MATLAB 内记录 candidate 的首次 `locate_i8(k,1,1)`，标为 `first_call`。两者分开，进程 wall time不能作为 evaluation time。
2. 对 candidate 再执行一次明确标为 `warmup` 的单点调用，不纳入三次基线统计。
3. 对 candidate 连续执行三次 unprofiled 单点调用，保存每次完整时间和四指标。
4. 对 ordinary neighbor 先执行一次 `warmup`，再连续执行三次 unprofiled 单点调用，同样保存全部原始值。
5. 若有补充诊断入口，在相同 warmed 进程中对两个点各运行至少一次无 profiler 分层计时；其 `full_total` 必须覆盖整个点函数。

每点报告三次完整时间的最小值、中位数、最大值。性能代表值取中位数；最小值仅作为低干扰观察，不能挑最快一次替代全部结果。首次调用、warmup 和 profiler-on 调用各自单列，不进入 warm median。

## 5. 互斥阶段账目

一级账目优先从原始 `locate_i8` profiler 的 caller-line 与 parent-edge 形成，不因计时本身复制公式。原入口的 `LOCAL_point` 依次调用 `LOCAL_cellsub`、`LOCAL_dtn`、`LOCAL_center`，再完成 matching/weights/SVD；其中 `LOCAL_cellsub` 内的两次 `LOCAL_qzsub` 必须从 lead construction 中分出。只有 profiler 导出的 line/edge 语义不能可靠形成以下互斥账目时，才启用第 3 节的补充入口。

| Stage | 包含内容 |
|---|---|
| `lead_construct` | lead 的 Rayleigh channels、圆几何、`kernel.precomp_proxy` 和一次 `bloch.construct_S`；不含后续 QZ/DtN |
| `qz_dtn` | 两个 generalized Schur 子空间、资格检查和两侧 DtN |
| `center_construct` | 中心的 Rayleigh channels、星形几何、`kernel.precomp_proxy` 和一次 `bloch.construct_S` |
| `matching_svd` | $A_{\rm def}$、权重、$A_{\rm phys}$ 与两个 SVD 的四指标 |
| `unattributed` | 对应分母减去以上四项；可能来自入口管理、warning guard、未显式列出的 profiler 行和计时误差 |

若使用原入口 profiler，账目分母取该次 profiled `LOCAL_point` 的相同口径总量，四项全部来自同一 call tree；若使用补充入口，分母才取其 `full_total`。两种账目都只对互斥块求和，并要求报告 `unattributed/denominator`；若其绝对占比超过 $5\%$，必须解释，不能把差额随意分摊。profiler 一级占比是 profiler-on 域内的归属；warm unprofiled wall/entry 时间另报，不能把一个域的秒数直接塞进另一个域。lead 与中心的比较使用各自完整 construction 时间，同时列出各自 proxy precomputation 与 `construct_S`，避免因包含范围不同造成假差别。

代码静态上每点存在两类相同参数的重复工作，运行记录应以 call count 核对：

- lead 与中心各调用一次 `kernel.precomp_proxy`，其输入 `k,beta,d,H,proxy_dist,nside,ntop,nproxy,mpw` 完全相同；
- `bloch.rayleigh_channels` 也以相同 `k,beta,d,M,X_R-X_L` 调用两次。

这不表示两个 `construct_S` 可合并：圆与星形的几何、内部波数和 BIE 矩阵不同。每个 `construct_S` 已把 `B_L`、`B_R` 合成一个 `rhs_all`，并通过一次 `A_QP \ rhs_scaled` 完成多右端求解；不得把它误报为逐右端重复分解。跨 benchmark repeat 的整点重算是测量协议，不计入“单点评价内部重复”。

## 6. Profiler 归属与细分

profiler 只用于必要的少量 warmed 单点。先在 candidate 做一次详细 profile；若它已经清楚分离最大项，ordinary neighbor 只做相同热点的针对性 profile/call-count 确认。profiler-on 总时间单独报告，不能替代 unprofiled 基线。

保存原始 `profile('info')` 数据和可读表。每项同时标注：

- cumulative/inclusive time：该函数连同子调用的时间；
- self/exclusive time：只属于该函数本身的时间，或由 profiler 明确支持的数据推得的互斥时间；
- call count 和 parent/child locator。

父函数 cumulative time 与子函数 cumulative time不得相加。一级阶段占比优先来自同一次原入口 profile 的互斥 caller-line/parent-edge；profiler 也用于在昂贵阶段内继续定位，不用 nested totals 另造一个总和。若当前 profiler 导出无法可靠得到 self time、同名函数的 parent-specific 时间或 line-level built-in 时间，对应栏写“尚未分离”，再判断是否需要最小补充入口。

在 `kernel.precomp_proxy` 与 `bloch.construct_S` 内至少尝试分辨：

1. proxy 预计算的矩阵形成与 `lsqminnorm`；
2. `op.construct_A_QP` 中 `kernel.qpgreen_mfs_pairmat` 的周期核及导数评价；
3. `qpgreen_mfs_pairmat` 内经 `LOCAL_h2d_chunked_public` 调用的 smooth proxy correction field；
4. 同一 pairmat 中 center-image/free-space `kernel.h2d_directch`、pair-difference 临时数组、phase/plane-wave 和其他工作；
5. `construct_A_QP` 的其余 free-space Hankel/Kress split、regular diagonal 和矩阵装配；
6. `construct_S` 的 $512\times512$ BIE multi-RHS solve；
7. incident/far-field、scattering blocks 和其他显著开销。

第 3 项才是“proxy 场局部展开”直接要替代的目标。若 profiler 只能证明整个 `qpgreen_mfs_pairmat` 昂贵，却不能把 smooth proxy correction 与 free-space/临时数组分开，结论只能是“periodic pairmat 是热点，局部展开收益尚未分离”。

## 7. 数值一致性

原入口各次重复均保存四指标；优先检查逐位一致，再报告每列 range。历史证据给出 candidate 的 run-17/run-18 零差，以及 ordinary neighbor 在 run-06/run-07/run-08 的零差，因此任何新非零 spread 都必须披露，不能只报汇总时间。

若建立补充入口，对每个 $k$ 都与同一 warmed 进程中的 `locate_i8(k,1,1)` 直接比较四指标。设计目标为相同运算顺序下逐位一致；实际交付列出绝对差。仅当比较量远离零且 relative difference 有解释力时再列相对差；candidate 的 $10^{-16}$--$10^{-14}$ ratio/sigma 不能只用相对误差判定。若不逐位一致，必须定位为普通计算顺序舍入或实现偏离；在未解释前不得以更短耗时支持优化结论。

## 8. 环境、资源和失败证据

记录 MATLAB `version`、`computer`/平台、可实际查询到的 computational-thread 设置及查询方式、进程开始前的其他活跃 MATLAB、每次运行的 process-tree peak RSS 与明显系统负载干扰。查询不到的线程信息写 `unavailable`，不猜测。资源监控还需把 MATLAB 启动/退出与入口内部时间分开。

本任务总时限为 60 分钟；MATLAB 科学诊断预计控制在 10 分钟内。一个完整正确配置的 attempt 仍服从 30 分钟 soft wall limit、最多一次“即将完成”的 10 分钟 grace 和 40 分钟 hard stop，process-tree peak RSS 硬限为 2 GiB；不得沿用旧任务 45 分钟／3 GB 预算，不得并发 MATLAB。操作性失败在同一 `attempt-1` 内修复和重跑，保留原始日志；不能另建 attempt 或为了理想数字反复试跑。

## 9. 判断门与交付

重要结论使用以下状态：`ESTABLISHED`、`CONDITIONAL`、`PROVISIONAL`、`REFUTED` 或 `BLOCKED`。

- 若一级互斥账目在两个点都显示同一最大阶段，记为 `ESTABLISHED` 的 baseline-config 数值热点；若排序变化，只报告点依赖。
- 只有 smooth proxy correction field 已被独立分离、在两个点都占据可观且稳定的完整点时间，才可把“下一步优先研究局部展开”记为 `GO`。作为预注册解释线，占比至少 $30\%$ 支持明确优先级；低于 $15\%$ 时，即使该项免费消失，Amdahl 理想上限也小于约 $1.18\times$，不支持把它列为首要优化；中间区间或只在一个点分离时记为 `CONDITIONAL`。
- 对任一拟优化份额 $f$，只报告基于耗时占比的理想上限 $S_{\max}=1/(1-f)$，明确这是估算，不是已实现加速。实际局部展开仍有构造成本，真实收益会更低。
- 若完全相同的 `precomp_proxy` 重算占据显著份额，先建议研究单点内复用；若其占比较小，而 smooth field 占主导，再建议局部展开。若 BIE solve、QZ/DtN、SVD 或 Kress/free-space assembly 更大，则建议对应热点。不得实施建议。

完成门为：原始计时齐全、对象和口径明确、四指标一致性可解释、资源未超限、父子耗时没有重复相加、独立 Skeptic 已检查原始 profiler 与计时文件。blocker 仅包括计时对象混入其他配置、数值内容偏离且未解释、资源超限使必要数据缺失，或原始 evidence 无法重建表格。profiler 不能细分某一子项是 important caveat；未认证、未证明收敛和未实施加速不是 blocker。

Engineer 在 `test/i8/profile-v1/` 保存可重复入口、运行说明、逐次时间、四指标、环境/资源、原始 profiler 数据及简洁账目。Skeptic 独立检查这些原始文件和相关源代码，再写 `r-profile.md`。I8 README 只登记本诊断、链接、结论边界与下一步建议；完成后停止。
