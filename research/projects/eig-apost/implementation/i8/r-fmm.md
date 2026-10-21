# I8 FMM2D 固定点对照独立审查

本记录由 Skeptic 独立只读审查后提交，主代理负责落盘。Skeptic 未启动 MATLAB。

## A. 审查对象与方法

审查对象是 I8 内部 `I8-FMM2D-V1`：冻结 I8.1 模型和
`(ntot,nside,ntop,nproxy,mpw,M)=(256,160,160,80,32,48)`，只将
`kernel.qpgreen_mfs_pairmat` 的 smooth proxy evaluator 换为官方 FMM2D，
检查五个历史 $k$ 点的场、矩阵、四指标和两点完整评价耗时。
排除扫描、重新定位、I8.2/I8.3、认证、缓存和其他新算法。

只读检查了 [[research/projects/eig-apost/implementation/i8/p-fmm|设计]]、
[[research/projects/eig-apost/implementation/i8/README|I8 README]]、
[[test/i8/fmm-v1/README|实验 README]]、原定位入口、两份新 MATLAB 源码、
监控脚本、公共核，以及官方提交 `550dae5b77b1e006c8ffae37fc832f8c2b536871`
的 `hfmm2d.m`、`helmkernels2d.f`、`hfmm2d.f`、三份构建日志和正式 run-01。

原始 MAT 由只读 MATLAB-v5 解析器直接读取，复数数组和 struct 进入已有 NumPy 2.3.5。
Frobenius/谱范数由 `numpy.linalg.norm` 重算，奇异值采用 NumPy 的
Accelerate BLAS/LAPACK SVD。全部5个 direct、10个 FMM 文件均已检查。
矩阵差 CSV 与 raw 重算最大绝对差为 $6.1\times10^{-28}$，场差为
$2.3\times10^{-23}$。

独立 SVD 不要求与 MATLAB `svd` 逐位相同。15组 direct/FMM 矩阵中，
stored 与 NumPy 重算的最大绝对差分别为：

| 指标 | 跨 SVD 实现的最大绝对差 |
|---|---:|
| `adef_sigma` | $6.67\times10^{-14}$ |
| `adef_ratio` | $1.10\times10^{-16}$ |
| `aphys_sigma` | $8.88\times10^{-16}$ |
| `aphys_ratio` | $3.11\times10^{-16}$ |

近秩亏 `Adef` 对 LAPACK 路径敏感；这些差异限制底部数值的强解释，不是
FMM/direct 同一 MATLAB 路径比较失败。MATLAB 内部 direct/original/历史四指标
的逐位复现另由 raw 数值核对。

## B. 结论

**PASS WITH CONDITIONS，高置信度，无 blocker。**
固定五点证据完整且可解释。两点 warmed 完整评价中位数缩短约6.23–6.53倍；
两档均保留五点近/远谷底层次，`1e-12` 的场和 $A_{\rm phys}$ 扰动明显较小。
支持继续评估粗搜索与“前期 FMM、最终 direct”流程，不支持替代末轮 ulp 级
精定位，也不能把请求容差当作误差界。

## C. 最强挑战

候选处 direct `aphys_sigma=4.3645331331577957e-14`。
`1e-10` 的 $\|\Delta A_{\rm phys}\|_2=2.65214\times10^{-13}$，
为 direct 最小奇异值的6.08倍，`aphys_ratio` 从
$1.52832\times10^{-14}$ 变为 $7.53594\times10^{-14}$。
`1e-12` 明显改善，但谱扰动仍为 $1.17868\times10^{-14}$，约为 direct
最小奇异值的27%，ratio 绝对差仍为 $1.01931\times10^{-15}$。
五点排序保持不能排除未测 ulp 邻点换序。当前证据的薄弱处是
“FMM 可直接承担最终精定位”，不是固定点加速本身。

## D. 分级发现

1. **Important caveat：五点不覆盖扫描与末轮平台。**
   两档均保持 candidate 最小、near 低于 far，但候选矩阵扰动与底部尺度不可忽略；
   独立 SVD 的舍入差也支持保留这一限制。粗搜索支持有条件，最终精定位替代未建立。
   本轮不需补跑；后续若获授权，应比较有限扫描的候选集合，并对入选候选直接法复核。
2. **Minor caveat：性能和构建可移植性有限。**
   仅测本机11线程、每方法3次；一分钟 load 为2.716–13.416；
   MEX 保留 macOS 14 object / target 11 的链接提示。
   不影响当前结果，但不能将倍速外推到其他平台或线程数。

没有 blocker。README 曾将尚未 stage 的源码称为 “tracked”，已改为
“not ignored and eligible for version control”，该文案问题已解决。

## E. 实现、原始数据与资源审计

- 对照源代码，模型、几何、BIE、密度缩放、QZ/DtN、matching、weights 和 SVD
  计算保持原路径；数值开关仅进入 `pars.h2d_evaluator`。自由空间原点项仍使用
  公共 `kernel.h2d_directch`。
- 每胞元一次 FMM，320源、65536目标；没有分批、建树缓存或跨点复用。
  direct/FMM 的 sources、charge、target、wavek 和胞元顺序逐位相同。
  20次精度对照调用均 `ier=0`，raw 场有限且形状为 `1x65536`、`2x65536`、
  `3x65536`；正式性能另有32次成功调用。lead/center 最小源目标距离分别为
  0.3与0.2990657022。
- 官方与公共核均使用 $\mathrm{i}H_0^{(1)}/4$、`target-source`、
  gradient `(x,y)` 和 Hessian `(xx,xy,yy)`；官方 `dreorderi` 恢复目标输入顺序。
  六分量 raw 比较未显示固定缩放、符号或行置换错误。
  最大 scale-safe infinity/Frobenius 场误差为 `1e-10` 的
  $2.439657\times10^{-11}$ / $1.497855\times10^{-11}$，
  `1e-12` 的 $7.200070\times10^{-13}$ / $3.354142\times10^{-13}$。
- 五点 direct 四指标与同进程 original 逐位相同，original 与冻结历史行也相同。
  所有矩阵工程标记和 Weyl 检查通过。最大相对 Frobenius 差按
  `1e-10` / `1e-12` 排列：`Adef` 为
  $3.294\times10^{-16}$ / $2.941\times10^{-16}$，
  `Aphys` 为 $1.419\times10^{-14}$ / $7.986\times10^{-16}$。
  `Adef` 已处于舍入尺度，不能仅凭收缩较小认定 FMM 不收敛。
- 独立重建第三档判定：十个矩阵 rel-F 收缩因子 median 9.344589、
  min 1.048008、max 23.852802；无 `eps12 > 2*eps10`，候选底噪条件也为 false。
  `triggered=false`，未运行 `1e-14` 符合冻结设计。
- 正式 outer timer 包住整个 `fmm_i8_point`，包含输入检查、reshape、
  FMM 建树/近场/重排、两胞元、QZ/DtN、matching 与 SVD。
  性能重复关闭 raw 场捕获，比较和导出在计时外；首次 MEX 加载只影响精度对照样本，
  正式性能另有显式预热。中位数如下。

| 点 | direct 秒 | FMM `1e-10` 秒 | FMM `1e-12` 秒 | 两档实测倍速 |
|---|---:|---:|---:|---:|
| candidate | 8.021870 | 1.287411 | 1.252893 | 6.231 / 6.403 |
| 近右点 | 7.981568 | 1.222257 | 1.223433 | 6.530 / 6.524 |

两档小时间差不支持容差成本单调结论。正式 run-01 exit 0，
总 wall 199.293856秒，峰值采样 RSS 1,155,547,136 bytes，没有其他 MATLAB，
满足30分钟与2 GiB预算。构建只用已有 make/gfortran/clang/MATLAB/libgfortran/libgomp；
未见隐式 package install。

## F. 经受审查的用途结论

1. 官方来源、commit、核约定和数组布局可追溯，raw 场排除了常见映射错误；
   direct 入口忠实复现原入口，收益没有来自删减计算、缓存或只计内核。
2. `1e-12` 在五点降低场与 $A_{\rm phys}$ 扰动，完整点评价成本与 `1e-10` 接近。
3. **粗搜索：CONDITIONAL。** 五点结构和两点速度支持继续测试，没有全区间漏检证据。
4. **最终精定位：NOT ESTABLISHED。** 当前不能批准替代末轮 ulp 平台评价。
5. **混合流程：当前最有依据的后续方案。** 优先 `1e-12` 形成候选，再用直接法完成
   最终定位和复核；这是建议，未在本轮执行。

## G. 最小处置

当前里程碑不需补跑或改变算法。保留 raw、构建失败日志和限制；
仅当用户另行授权粗扫描时才做预注册有限对照。本轮停止，不进入扫描、缓存、
其他局部展开、容差调优或 `1e-14`。

## H. 问题交接

集中登记在 [[research/projects/eig-apost/implementation/i8/README#历史基线与遗留问题|I8 问题表]]：

| 条目 | 类别 | 受限范围 | 最小后续检查 | 状态 |
|---|---|---|---|---|
| I8-F1 | important caveat | 整段扫描、漏检、最终精定位替代；非当前交付 blocker | 获授权后有限扫描比较，入选候选直接法复核 | OPEN |
| I8-F2 | minor caveat | 跨平台/线程速度外推 | 迁移时重建及两点三重复 | WONT-FIX FOR CURRENT CLAIM |
