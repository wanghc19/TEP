# I8 smooth-proxy FMM2D 对照设计

## 1. 问题、范围与状态

- Design ID: `I8-FMM2D-V1`
- Status: `FROZEN FOR EXECUTION`
- Research question: 在 I8.1 冻结单点评价中，只把 smooth proxy correction callback 从直接求和换成 FMM2D，能否在五个既有 $k$ 点保持可解释的矩阵与四指标一致性，并在候选及正常邻点上减少完整单点评价时间？
- Success criterion: 官方 FMM2D 来源和核约定可核查；五点 direct/FMM 数据齐全；矩阵、场和四指标差异可解释；两点 warmed 性能记录完整；资源未越界。

本实验是 [[research/projects/eig-apost/implementation/i8/p-profile|I8 单点评价耗时诊断]] 的有限后续，仍属于 I8 内部里程碑。它不建立新阶段，不扫描或重新定位候选，不改变模型、空间参数、匹配公式、QZ/DtN、BIE 求解或奇异值定义，也不运行 `check_i8`、`estimate_i8`。即使 FMM 更慢或精度不足，完整的负结果也算合格交付。

权威计算对象为当前 `codex/epost` 工作树 HEAD `3d20a4e39fe37dbfd99d517543f0e38aa5c8c89f` 下的 [[test/i8/locate-v1/locate_i8|locate_i8]]、公共 `kernel.qpgreen_mfs_pairmat` 的 evaluator hook、公共 `kernel.h2d_directch` 及本设计。实验不得修改或遮蔽公共 `+kernel`、`+op`、`+bloch`、`+geom`，也不得修改既有 locate/check/estimate/profile 实验。可执行入口不得读取 Markdown、Git、历史输出或硬编码本机绝对路径；HEAD 和历史指标只由外层记录人工核对。

## 2. 冻结模型、空间和五点

所有调用使用同一 I8.1 配置：$\beta=0.5$；左右 lead 为半径 $0.2$、`epsrel=17` 的圆；中心为六行几何数据同时乘 $\sqrt{0.04/0.0618}$、`epsrel=2` 的单连通光滑五瓣星形；

```text
(ntot,nside,ntop,nproxy,mpw,M) = (256,160,160,80,32,48)
K = 2*M+1 = 97
```

每个 inclusion 的内部 BIE 为 $512\times512$，$A_{\rm def}$ 与 $A_{\rm phys}$ 均为 $194\times194$。公共 `bloch.construct_S` 保持当前 density coordinate scaling，并继续一次求解合并后的左右多右端；不得恢复历史缩放或拆回逐右端分解。

五点按下列 literal 和顺序冻结。四指标顺序均为 `adef_sigma, adef_ratio, aphys_sigma, aphys_ratio`；它们只供结果核对，不成为 MATLAB 入口的控制数据。

| Role | $k$ literal | 既有 I8.1 机器记录 | 历史四指标 |
|---|---:|---|---|
| far left | `1.7562800000000001` | `locate-v1/output/attempt-1/run-04/scan.csv:7`；run-03/05 亦重复 | `(1.5876231719907793e-05, 2.6277513150613766e-08, 7.8518431836730985e-06, 2.7494686301593299e-06)` |
| near left | `1.7562818432000002` | `run-07/scan.csv:6`；run-08 首点亦重复 | `(5.841854800507074e-08, 9.6691342793425702e-11, 2.8891800391280084e-08, 1.0117017608828445e-08)` |
| candidate $k_0$ | `1.7562818500073463` | `run-17/scan.csv:10`；run-18 新进程单点逐位复现 | `(9.0463849720091667e-14, 1.4973105978156506e-16, 4.3645331331577957e-14, 1.5283249311405522e-14)` |
| near right $k_1$ | `1.7562818560000002` | `run-07/scan.csv:7`；run-06/08 亦重复 | `(5.1427176954783761e-08, 8.5119588994282451e-11, 2.5434108843217626e-08, 8.9062407543503152e-09)` |
| far right | `1.7562832000000002` | `run-04/scan.csv:9`；run-03/05 亦重复 | `(1.1585222925247052e-05, 1.9175258534932009e-08, 5.7296486607576744e-06, 2.0063488307499211e-06)` |

近点距 $k_0$ 分别约 $-6.8073\times10^{-9}$ 与 $+5.9927\times10^{-9}$，位于同一局部谷底但不属于末轮 ulp 平台。远点距 $k_0$ 约 $-1.8500\times10^{-6}$ 与 $+1.3500\times10^{-6}$，历史 `aphys_ratio` 比候选平台高约 $10^8$ 量级。因此五点同时检查近平台灵敏性和明显离开平台后的行为；本轮不得为选点追加扫描。

## 3. FMM2D 来源、安装边界与 API 契约

唯一获准的外部依赖是官方 `flatironinstitute/fmm2d`：

- source URL: `https://github.com/flatironinstitute/fmm2d.git`；
- local source: `test/i8/fmm-v1/vendor/fmm2d`；
- frozen commit: `550dae5b77b1e006c8ffae37fc832f8c2b536871`；本轮按 commit 固定，不指定 release/tag；
- license: 原仓库 Apache-2.0 `LICENSE` 原样保留；
- platform/toolchain: arm64 macOS 14.8.7、GNU make 3.81、已有 Homebrew gfortran 14.2、Apple clang 15；采用仓库自带 `make.inc.macos_arm64.gnu` 和官方 GNU make 的 `make matlab` 路径。CMake 未安装，但该构建路径不依赖 CMake。

安装记录必须保存 exact clone/checkout/build 命令、编译 stdout/stderr、MEX 文件名、`which('hfmm2d')`、`which('fmm2d')` 和加载检查。不得安装、升级或隐式下载其他软件包；若现有编译器、MATLAB MEX 或系统库仍缺少依赖，立即停止并向用户报告，不得扩大授权。

官方 `matlab/hfmm2d.m` 与 `matlab/fmm2d.mw` 定义的 Helmholtz kernel 已经是

$$
G_k(x,y)=\frac{\mathrm{i}}4 H_0^{(1)}(k\lVert x-y\rVert),
$$

与公共 `kernel.h2d_directch` 相同。因此传入 `proxy.q` 时**不得**再乘 $\mathrm{i}/4$。实验 callback 固定使用

```matlab
srcinfo.sources = sources;       % 2-by-ns
srcinfo.charges = reshape(charge,1,[]); % complex 1-by-ns
[U,ier,timeinfo] = hfmm2d(eps,wavek,srcinfo,0,targ,3);
```

并映射 `U.pottarg`、`U.gradtarg`、`U.hesstarg` 到原 callback 的 `pot,grad,hess`。官方 wrapper 返回 target potential 为 `1-by-nt`、gradient 为 `2-by-nt`、Hessian 为 `3-by-nt`；官方 `src/helmholtz/helmkernels2d.f` 的行序是 `(x,y)` 与 `(xx,xy,yy)`，与公共 direct kernel 完全相同。梯度是 target derivative，因为底层取 `targ-sources`。FMM 调用使用缺省 `opts`，不调 `ndiv`、`idivflag` 或 `ifnear`；每次要求 `ier==0`。

不建立独立的 synthetic preflight 或另一个验证阶段。MEX 的实际加载、`ier`、形状、finite、最小 source-target 距离和六分量检查都融入第一次所选五点 I8 完整调用：由该点 lead 和 center 的真实 smooth callback 捕获 `sources,charge,targ` 与输出，完成评价计时后再比较 direct/FMM。这个实际调用同时检查 normalization、source/target 符号、gradient 顺序和 Hessian 行置换；若出现固定比例、符号或行置换证据，不得用更严 tolerance 掩盖接口错误。

## 4. 最小实验入口

在 `test/i8/fmm-v1/` 建立一个不同名的诊断入口，只复制 `locate_i8` 形成同一点所需的 `LOCAL_` helpers，并明确标出来源与唯一计算差别：给两处 `pars.h2d_evaluator` 选择 direct chunked callback 或 FMM callback，同时可返回 $A_{\rm def}$、$A_{\rm phys}$。模型、几何、QZ/DtN、matching、weights、SVD 和公共 package 调用保持原运算顺序。direct callback 保持原 512-target batching；FMM callback 可把同一 `T_in` 整批交给 `hfmm2d`，但不得删减 target、source、梯度或 Hessian。

提供三种运行角色：

1. `original`: 直接调用未经修改的 `locate_i8(k,1,1)`，只取四指标；
2. `direct`: 诊断入口使用原 chunked public direct callback，并导出两矩阵与四指标；
3. `fmm`: 同一诊断入口只换 smooth callback，`eps` 固定为 `1e-10` 或 `1e-12`。

五点准确性调用不使用双算 comparison callback。direct 与 FMM callback 各自只计算所选方法，同时在点计时内捕获该次 lead/center 的原始 `pot,grad,hess`；计时结束后才用同一点 direct 捕获值形成场差摘要。这样每个 $k$/tolerance 都有一条有效的完整单点评价时间，且 FMM 样本没有混入 direct 求值。正式三次 repeat 关闭原始场捕获，不执行差分、日志序列化或 profiler。

执行入口只接收明确的 output directory、方法、tolerance 和 $k$。五点 literal、冻结模型及空间参数写在实验 MATLAB source；入口不得从历史 CSV/MAT/JSON、Markdown 或 Git 获取数值。外层 launcher 负责路径、监控和来源记录；实验不得通过 package shadow 改变函数解析。

## 5. 五点数值协议与导出

MATLAB 串行执行，不允许第二个代理或第二个 MATLAB 同时运行。外层先完成 source/build 记录；MEX 的实际 load 与运行检查随第一个真实 I8 点发生，不另建阶段。然后按固定五点顺序进行：

1. 每点调用一次 `original`，记录完整单点评价时间与四指标，并在运行后与第 2 节历史行人工比较；
2. 每点调用一次 timed `direct`，保存该次完整点时间、$A_{\rm def}$、$A_{\rm phys}$、四指标及两胞元原始场，要求与同进程 `original` 直接比较；
3. 每点对 `eps=1e-10` 和 `eps=1e-12` 各调用一次 timed `fmm`，保存完整点时间、两矩阵、四指标、两胞元原始场和 FMM `ier/timeinfo`；
4. 停表后再比较该点 direct/FMM 原始场、矩阵和指标并序列化 MAT/CSV/JSON。五点各方法的单次时间属于 accuracy-run timing，只描述该实际调用，不替代第 7 节三重复性能统计。

每个方法/点至少导出：实际 $k$、方法和 `eps`，四指标，完整 $194\times194$ 的 $A_{\rm def}$ 与 $A_{\rm phys}$，矩阵维数与 finite 检查。每个 FMM smooth call 的场摘要至少包含 `ns,nt`、最小 source-target 距离、`ier,timeinfo`，并对

```text
pot, grad_x, grad_y, hess_xx, hess_xy, hess_yy
```

逐分量保存 direct/FMM 的 norm、最大幅值、最大绝对差、Frobenius 差及以下两个 scale-safe 误差：

$$
e_\infty(X)=\frac{\max|X_{\rm fmm}-X_{\rm dir}|}
 {\max(1,\max|X_{\rm dir}|)},\qquad
e_F(X)=\frac{\lVert X_{\rm fmm}-X_{\rm dir}\rVert_F}
 {\max(1,\lVert X_{\rm dir}\rVert_F)}.
$$

矩阵比较保存 `maxabs`、absolute/relative Frobenius norm 和 spectral norm。四指标保存绝对差；只有 direct 值明显离开零时才解释相对差。候选的 $10^{-16}$--$10^{-14}$ 指标以绝对差和矩阵扰动为主，不能因相对误差大而单独判失败。对两个最小奇异值另核对 Weyl 尺度

$$
|\sigma_{\min}(A_{\rm fmm})-\sigma_{\min}(A_{\rm dir})|
\leq \lVert A_{\rm fmm}-A_{\rm dir}\rVert_2
$$

至 ordinary floating-point 余量；ratio 的分母也应单列，不能把 ratio 差误称为同一个 Weyl bound。

## 6. 预注册准确性标记与第三档触发

实现状态首先记录 `ier`、形状、finite 和 coincidence。六个场分量在每个真实 callback 上另计算以下工程质量标记：

$$
\max(e_\infty,e_F)\leq 1000\,\varepsilon_{\rm fmm}.
$$

`1000*eps` 只是排查映射错误和比较 tolerance 的经验线，不是 FMM2D 的严格误差定理，也不是完成本实验的 blocker。两矩阵同样记录 relative Frobenius error 是否低于 `1000*eps`，并同时检查：

- `direct` 四指标与同进程 `original` 逐位一致；若复制入口引入普通舍入，必须用两矩阵与运算顺序定位解释，否则是 blocker；
- `eps=1e-12` 是否比 `eps=1e-10` 的同类场/矩阵误差系统性恶化超过两倍；
- 在五点内，candidate 是否仍是 `aphys_ratio` 最小点，两个 near 点是否仍明显低于两个 far 点；
- 所有 metric 差以 absolute 数值完整披露，尤其不得宣称 FMM 重现了 candidate 的 binary64 平台位置精度。

超过经验线、非单调或五点排序改变本身都是应报告的科学结果，可得到 `CONDITIONAL` 或 `REFUTED`，不自动表示实现错误，也不阻止负结果交付。只有形状不合、固定 normalization/sign/row permutation 等证据才表明 callback 映射错误。

两档无论成败都保留。第三档在看结果前固定为 `eps=1e-14`，只有没有 callback 映射错误、所有 `ier==0` 且剩余预算允许，并满足以下至少一项才触发：

1. candidate 的 `eps=1e-12` `aphys_sigma` 大于 direct 的三倍，且 $\lVert A_{{\rm phys},\,12}-A_{{\rm phys},\,{\rm dir}}\rVert_2$ 大于 direct `aphys_sigma`，说明候选底噪仍可能由 FMM 扰动主导；
2. 五点、两矩阵共十个 relative Frobenius error 从 `1e-10` 到 `1e-12` 的中位收缩因子小于 5，或任一矩阵误差恶化超过两倍，因而收紧趋势尚不清楚。

若触发，`eps=1e-14` 必须覆盖全部五点 validation，并在 `k0/k1` 执行相同 warmup 加三次 repeat 的性能协议，不能只挑 candidate 或单个好看结果。若存在固定比例、符号、行置换错误，应先判为映射问题，禁止靠收紧 tolerance 掩盖；`ier` 非零则保留为该 arm 的原始失败证据。不得改用其他第三档或增加第四档。

## 7. 正式性能协议

正式性能只测 candidate `k0=1.7562818500073463` 和正常邻点 `k1=1.7562818560000002`。方法为 `direct`、`fmm eps=1e-10`、`fmm eps=1e-12`；第三档只有触发后才加入。每点每方法先一次明确 `warmup`，再三次无 profiler 完整评价。三轮 repeat 采用固定循环次序以分散 run-order drift：

```text
round 1: direct, fmm-1e-10, fmm-1e-12
round 2: fmm-1e-10, fmm-1e-12, direct
round 3: fmm-1e-12, direct, fmm-1e-10
```

若第三档触发，则 warmup 和三轮 repeat 使用四方法同样的固定左轮换，不临时选序：

```text
warmup/round 1: direct, fmm-1e-10, fmm-1e-12, fmm-1e-14
round 2: fmm-1e-10, fmm-1e-12, fmm-1e-14, direct
round 3: fmm-1e-12, fmm-1e-14, direct, fmm-1e-10
```

另一个点重复同一协议。每个样本从诊断 point entry 前开始，到两矩阵和四指标形成后停止；它必须包含输入 reshape、FMM tree/build/reorder、near/direct work、输出 reshape、两胞元构造、QZ/DtN、matching 和 SVD。MEX 首次加载只进入 warmup。矩阵差、汇总统计、文件写入及 MATLAB 启动/退出不进入样本。不得预建并跨评价复用 FMM tree，也不得只计 FMM2D 的内部 `timeinfo`。

每点每方法报告三次 wall time 原值及 min/median/max；性能代表值取 median。实际完整点 speedup 只写为 `median_direct/median_fmm`，不得挑最快一次。若某 tolerance 超过第 6 节经验线或改变五点排序，其时间仍报告，但不能直接作为数值可接受替代的加速结论。正式运行不开 profiler；历史约 8 秒只用于预算，不是本轮测量。

## 8. 环境、资源与失败证据

记录 MATLAB version/platform、实际可查询线程设置、FMM2D commit/build、MEX 解析路径、运行前及运行中是否有其他 MATLAB、process-tree peak RSS、总进程 wall time和明显系统负载。MATLAB 启动/退出与单点评价时间分开。

总任务时限从 2026-10-20 15:14:47 UTC 起 90 分钟。科学运行服从 30 分钟 soft limit、最多一次即将完成的 10 分钟 grace、40 分钟 hard stop和 2 GiB process-tree peak RSS 硬限。按历史 direct 时间，五点 validation 与两点正式 repeats 应在约 10 分钟内；若 build 或第一个实际点显示可能越过资源限制，先停止并报告。所有 MATLAB 运行串行。

操作性错误在同一个 `attempt-1` 内修复并重跑，保留失败日志；不得为理想时间另开 attempt 或反复挑样本。缺失的非 FMM 软件依赖是 blocker，必须询问用户。MEX build/load 失败、资源越界、direct 入口偏离原对象且无法解释，或五点必要数据缺失会阻止计划中的数值/性能比较；`ier` 非零或误差过大若来自实际 FMM 调用，则作为该 arm 的负结果保留，不因结果不理想另行试跑。

## 9. 判断边界与交付

结论分别标记 `ESTABLISHED`、`CONDITIONAL`、`PROVISIONAL`、`REFUTED` 或 `BLOCKED`：

- 只有某个 FMM tolerance 无映射错误、误差尺度对四指标用途可接受且五点行为可解释，才可称为该冻结配置下可接受的 smooth-callback 替代；超过经验误差线可正常得到负结论，不构成本实验 blocker；
- 只有它在 `k0`、`k1` 的 warmed median 都改善，才可称为两点上实测加速；若一点变慢，报告点依赖；
- 由五个固定点只能判断这五点的近/远结构保持，不能外推整段扫描、候选重定位、连续算子谱或认证误差；
- FMM2D 的 requested precision 不是本项目矩阵/谱指标的严格误差界；本实验仍是数值对照；
- 不复用相同参数的 `precomp_proxy`、Rayleigh channels 或跨点数据。本轮只回答 FMM 是否值得继续，完成后停止，不进入局部展开、参数调优或新扫描。

Engineer 在 `test/i8/fmm-v1/` 保存安装/运行说明、源码入口、失败日志、环境资源、原始 timing、完整矩阵 MAT 和场/矩阵/metric 摘要。Skeptic 必须从这些原始数据独立检查 source/version、API 映射、计时边界、五点 direct 历史复现、数值门及结论强度。I8 README 只登记本实验的最终短结论和链接；不建立重复 STATUS/SUMMARY 或新阶段目录。
