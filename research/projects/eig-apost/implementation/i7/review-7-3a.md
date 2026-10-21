# I7.3 跨离散符号计数与同模态稳定性独立审查

## 2026-09-29 修正公共密度坐标后的复验审查

本节记录 Skeptic 的独立只读审查，由主代理落盘。Researcher 核对冻结约定，Engineer 只最小修改
入口中的共同 $k_0$ 并执行受监控 MATLAB；Skeptic 未修改代码或另开 MATLAB。
下方原 A--H 及 §D.6 补充记录均保留为修正前历史，其旧 verdict 不代表本轮状态。

### A. 当前对象和边界

本轮固定 $k_L=1.753125,k_0=1.755995740875,k_R=1.75625$，两侧圆 `epsrel=17`、中心单个
椭圆 `epsrel_center=2`，六配置和辅助 tuple 保持设计冻结值。A 是 18 个固定点；B 是六配置的
共同 $k_0+(-5{:}5)10^{-5}$ 网格，共 66 点。两阶段及必要审计共享一次 1800 s 监控，
每 0.1 s 监测 MATLAB 进程树和全部 MATLAB 树并集，以 2.3 GB 提前终止，用户上限为 3 GB。
不增加 `AUX`、拟合参数检查、宽扫描、自动扩区/加密或理论认证。

### B. 当前 verdict

固定点 A 与局部位置 B 均已完成：**PASS WITH CONDITIONS（高置信度）**，无未关闭的 blocker。
18 个固定点、66 个局部点及各自的新矩阵审计全部有效。条件是保留下述有限矩阵、固定辅助
离散参数及有限采样网格的解释边界，不要求本轮追加实验。

### C. 代码、坐标与新矩阵复核

最小 diff 仅将 $k_0$ 在原入口定义一次，并传给 `LOCAL_local_scan`；公开接口和所有数值
helper 的公式、配置、权重、判号规则不变。center 与 half-guide 均直接调用已修正的公共
`bloch.construct_S`，入口没有重复缩放。公共修复内部以缩放右端求解，再逆变换回物理密度；
没有新建同名包或替代 BIE/QZ/DtN 实现。

固定点证据位于 `refine-v1/output/attempt-1/run-08/fixed/`。正式命令将同一次入口返回的
fresh `evidence` 直接传给既有 `audit_i7_refinement`，而非从结果表倒推矩阵。
该 audit 对实际新 $A_{\mathrm{def}},T,N_0,L,H,H_{\mathrm{sym}}$ 重算恒等式、右解残差、eig、
三档 $\eta$ 与计数，并重构 $A_{\mathrm{phys}}=D_rA_{\mathrm{def}}D_c$、
$q=D_cv$、$d=Tq$。$H_{\mathrm{sym}}$ eigenvector 已在物理 Dirichlet Fourier 坐标，
无需再乘 $T$；跨 $M$ 对左右墙分别按真实 $m$ 标签零填充，重算相位/尺度不变 overlap 和 tail。
Skeptic 独立审查了上述代码、命令调用顺序、运行时路径和源码快照，以及实际重算 defect；
这是对新矩阵重算过程的独立审查，不是另一个独立物理求解器。

### D. 固定点实测结论

- 18/18 点有效。六配置的三个 band 在左端均为 $n_-=0$、右端均为 $n_-=1$，端点 unresolved
  为零，全部得到 `JUMP`。中心 $k_0$ 三带各有一个 unresolved；它是近零诊断，不进入端点门。
- 全点最小 `rcond(T)` 为 $0.5169934488000495$；最大组装/右解误差分别为
  $8.292434072996824\times10^{-19}$、$3.775355659938805\times10^{-19}$。
  全部 QZ 方向均为 $K$ stable、$K$ unstable、0 neutral、0 indeterminate；无数值求解警告。
- 端点 $d_H$ 在约 $1.43\times10^{-13}$ 至 $2.63\times10^{-13}$，各配置按自身维数和范数
  重新计算三档 $\eta$，未沿用基线阈值。与修正后 I7.2 的肩点差异仅有普通 eigensolver 舍入，
  不作逐位谱值相等要求。
- 18 次配置边/对象比较全为 simple mode，最低 primary overlap 为
  `0.9999999999999994`，最高 competitor cross-overlap 为 $5.1934739087163063\times10^{-14}$，
  $|m|>48$ 最高能量占比为 $1.1929356645472612\times10^{-30}$。实际数据没有触发近简并，
  不能称实际验证了 cluster 稳定；已有分支和 oracle 保留，未强行配对。
- fresh audit 对全部 18 点、18 次比较通过；四指标最大绝对复算差为
  $4.5047767089100715\times10^{-18}$，物理迹相对复算差为 $1.2208197869149605\times10^{-16}$，
  overlap 最大差为 $4.4408920985006262\times10^{-16}$。A 入口耗时 $350.805217$ s，
  含保存、audit 和图的阶段耗时 $358.846955$ s。

### E. 局部位置与最终资源

- 六配置统一评价 $[1.7559457408749999,1.7560457408750001]$ 内的 11 点，名义间距
  $10^{-5}$；66/66 点有效。按 `aphys_ratio` 选出的最低点均为第 6 点
  $k_0=1.755995740875$，`aphys_sigma` 的最低点也一致，全部为内点。
  相对基线采样位置漂移均为零；结论严格为 `NO_DRIFT_RESOLVED_AT_SPACING_1E-5`。
- 全部 winner 的相邻点区间为 $[1.7559857408749999,1.7560057408750001]$，完整宽度
  $2.0000000000131024\times10^{-5}$；左右 ratio gap 均约 $1.4870\times10^{-5}>0$。
  该网格夹住采样低谷，不是连续最小点的位置误差界。固定点与局部扫描独立重算的 $k_0$
  四指标逐项最大绝对差为 0，没有复用旧矩阵作为输入。
- 66 次同 $k$ 物理迹配置边比较全部通过，最低 primary overlap 为
  `0.9999999999999994`，最高 competitor cross-overlap 为 $3.625173520650695\times10^{-14}$，
  $|m|>48$ 最高能量占比为 $8.582105533127304\times10^{-32}$。同配置网格迹与 $k_0$ 迹的
  最低 overlap 为 `0.999999999994562`。实际模态均为 simple mode。
- `audit_i7_local` 接收本轮刚返回的 `evidence`，从六个 winner 的新矩阵重构权重、
  $A_{\mathrm{phys}}$、$q=D_cv$ 与 $d=Tq$，并重算全部 66 条同 $k$ 比较。
  四指标最大复算绝对差为 $4.5047767089100715\times10^{-18}$，物理迹最大相对差为
  $1.2208197869149605\times10^{-16}$，比较值最大差为 $3.3306690738754696\times10^{-16}$；
  全部审计通过。Skeptic 核查了重算源码、实际 fresh-evidence 调用及输出，不仅核对表格内部关系。
- B 入口耗时 $1255.944696$ s，含保存、audit 和图的阶段耗时 $1259.272412$ s。
  A、B、两次审计和启动共同由单次 MATLAB 监控覆盖，实际耗时 $1630.584183$ s，
  低于共享的 $1800$ s 上限。16,306 个资源样本的进程树峰值为 **1,505,230,848 bytes**，
  MATLAB 树并集峰值相同，无外部 MATLAB。正常退出 `exit_code=0`、`termination=process exited`，
  未触发 2.3 GB 提前终止；没有程序失败或数值求解警告。日志中的两条 JVM 启动警告不属于数值求解警告。
- 证据、曲线、矩阵与完整命令均保存于 `refine-v1/output/attempt-1/run-08/`；历史 run 未覆盖。

### F. 科学解释与尚存限制

**IMPORTANT CAVEAT：** 两条已测离散轴稳定不等于全离散收敛。辅助拟合 tuple 保持固定，
不能把当前小变化归因于某个未变参数的误差已受控制。当前 $k_0$ 的 `aphys_ratio` 在 $M$ 轴、
`ntot` 轴的相对全范围分别约为 $5.40\times10^{-5}$、$3.86\times10^{-5}$，绝对变化约为
$10^{-15}$；图中纵轴放大不代表显著 dip 深度变化。`adef_ratio` 随 $M$ 约 25% 的变化包含
raw 最大奇异值随矩阵维数变化，不能解释为模态漂移。

**IMPORTANT CAVEAT：** 固定网格只能检验采样位置是否可分辨地变化，不能提供位置误差、
连续最小点收敛、raw-$H$ 严格惯性或连续特征值认证。小 $d_H$ 也不是严格 Hermitian 证明。
这些限制不要求本轮新增 `AUX` 或理论研究。

### G. 处置与历史边界

当前 A 与 B 均由新公共路径重新建立，不能沿用旧矩阵；旧端点的 $d_H\sim7\times10^{-3}$ 与新结果
已有实质变化。旧中心点为 $1.7545053299700002$，本轮中心点为 $1.755995740875$；两者的
四指标只作各自采样点的历史对照，不冒称 same-$k$ 回归或本轮六配置之间的离散漂移。

### H. 问题交接

当前 caveat 统一交给 [[research/projects/eig-apost/implementation/i7/README#I7 待办与问题|I7 问题表]]，
不复制新问题框架。完整可复现实验与当前表格见 [[test/i7/refine-v1/README|实验 README]]。

## 修正前历史审查与 2026-09-27 补充记录（原 A--H）

## A. 审查框架

- Audit target: [[research/projects/eig-apost/implementation/i7/design-7-3a|I7.3 design]]、
  `test/i7/refine-v1/check_i7_refinement.m`、mandatory `output/attempt-1/run-04/` 及后续授权的
  local-only `run-06/` 与 saved-data audit `run-07/`。
- Current stage: 固定物理模型的有限维数值稳定性检查；输出类型是可复现数值个案，不是谱认证或
  连续特征值证明。
- Success criterion: 18 点对象门全部有效；六配置在 $c=50,100,200$ 三条诊断带都保持左端
  $n_-=0$、右端 $n_-=1$；六条预注册 edge 上的三个同 $k$、同 operator 物理迹对象通过同模态门；
  local-only 六配置共用 11 点网格时不把缺失点或异 $k$ 向量冒充为位置稳定；
  mandatory 与 local scientific runs 均低于 3 GB，全部 MATLAB wall 保守累计低于 2700 s。
- Exclusions: 不从 $H_{\mathrm{sym}}$ 计数推出 raw $H$ inertia，不从 sampled dip 推出连续根、唯一性、
  位置误差或收敛阶。
- Authority checked: repository root/research/test `AGENTS.md`、I7.2 设计/审查/源程序、I2.3 的
  同模态比较方法、I7.1 保存点和本轮源程序、JSON/MAT audit、资源日志及失败日志。

## B. Verdict

**原实验审查结论：`PASS WITH CONDITIONS`**，高置信度；此结论作为历史记录保留。

**2026-09-27 补充审查：I7.3 物理解释仍须 `REVISE`。** §D.6 发现的公共 BIE 密度坐标错误已在
`bloch.construct_S` 中最小修正，并以圆控制、椭圆原始密度坐标参考解、三点 before/after 和 corrected
I7.1 wide scan 验证。下述 I7.3 数值仍是修正前有限矩阵快照；本轮未重跑 I7.3 的六配置端点、
同模态或局部位置比较，因此不能自动恢复其目标物理解释。

mandatory 结果支持声明强度为“六个有限离散对象在两个预注册轴及 joint corner 上保持相同
Hermitian-part endpoint jump 和同一物理迹 mode”。18/18 点有效，全部 hard comparisons 为
`SAME_MODE`，保存矩阵的独立重算通过。后续 66 点 local-only 网格在六配置都返回
同一中心 sampled winner，两侧相邻点严格更高，且 66 条同 $k$ edge 比较均通过。这只支持
“步长 $10^{-5}$ 的当前网格未分辨出位置漂移”。结论仍受固定 proxy/wall 拟合、有限 $k$
网格及 $H_{\mathrm{sym}}$ 代理性质限制，不能被表述为位置收敛、连续根或连续谱结论。

## C. 最强挑战

当前最强限制是六配置结果尚未在修正后的公共密度坐标链上重跑：公共源码和 corrected I7.1 已经
修复并验证所确认的密度坐标错误，但不能据此推定旧 I7.3 六配置的 endpoint count、同模态 overlap
和局部位置比较保持不变。最小决定性检查仍是以现行公共路径重跑 mandatory；是否需要 local-only
或 `J--AUX` 应由该结果决定。

六配置仅改变 `ntot` 与 $M$，而 `(nside,ntop,nproxy,mpw)=(160,160,80,32)` 保持不变。因此观察到的
平台也可能由固定 proxy/wall 拟合误差主导。这个机制不会否定“在所测两轴上稳定”，却会否定“已说明
总体离散误差已收敛”的更强解释。预注册 `J--AUX` 联合拟合加密是缩放问题排除后的后续检查；即使通过，也
只能说明这一组联合加密未破坏固定点结果，不能分离四个拟合参数的贡献。

## D. Findings

1. **IMPORTANT CAVEAT — 当前证据是有限矩阵诊断。** 位置：I7.3 design §§1,7；run-04
   `result.json`。证据：raw $H$ 的严格惯性明确标为不可用/未建立，计数只作用于
   $H_{\mathrm{sym}}=(H+H^*)/2$，且 $d_H\approx6.94\times10^{-3}$ 至
   $6.98\times10^{-3}$ 被保留在 $\eta_c$。后果：`STABLE_SAME_MODE` 不能推出 raw 实根、连续特征值、
   唯一性或误差界。最小下一检查：按 [[research/projects/eig-apost/implementation/i7/README|I7
   唯一问题表]] 的 I7-Q3 保留 claim boundary；本阶段无需打开新理论专题。

2. **IMPORTANT CAVEAT — 固定 proxy 参数限制平台归因。** 位置：design §§3,9。证据：六个 mandatory
   配置均使用 `(160,160,80,32)`，本轮仍未执行 `AUX`。后果：只可说
   结果对所测 `ntot`/$M$ 轴稳定，不能识别平台由哪个固定参数主导。最小下一检查：未来若要提高 claim，
   执行已冻结的 fresh `J--AUX` 三点联合拟合加密；本阶段不需要它才能通过。

3. **IMPORTANT CAVEAT — local 网格未分辨出位置漂移，不是位置收敛。** 位置：design §8；
   `run-06/result.json`。证据：后续授权的六配置各在
   $k_0+(-5{:}5)\times10^{-5}$ 的同一 11 点网格评价；66/66 点有效且诊断门通过，六个
   `aphys_ratio` argmin 都是 index 6 的 $k_0=1.7545053299700002$，实际左右相邻点全宽为
   $2.0000000000131024\times10^{-5}$，两侧 gap 都严格为正。后果：只能说这一固定步长网格
   “未分辨出漂移”，不能声称 minimizer 随离散收敛、达到 $10^{-5}$ 位置误差，或存在连续根。
   当前交付无需再加密；若要提高位置 claim，最小下一检查是预注册的更细或错位公共网格。
   相关连续/有限网格边界继续链接 README 的 I7-Q1。

4. **MINOR CAVEAT — 资源记录有一个不可补的早期空洞。** 位置：`output/attempt-1/run-01/`。
   证据：一次误启动的 `checkcode` MATLAB 在约 0.9 s 内 exit 137，未进入 scientific point，且 RSS
   未采样。另有用户报告的来源未知 17 GB MATLAB 事件，没有证据可归因于 I7.3。后果：不能声称本轮
   每一次 MATLAB 启动的峰值都已知；run-04 与 run-06 科学计算本身有完整 0.1 s 监测。
   最小下一检查：无需重跑
   失败命令；最终资源表分别报告未知与已监测调用。
   monitor self-test 覆盖内存早停、信号清理、锁拒绝和真实外部 MATLAB 的 preflight 拒绝，但没有
   成功注入“运行中才出现的外部 MATLAB”；该分支只经静态审查。run-04 实际 3652 个样本均无外部
   MATLAB，因此这是监控测试覆盖 caveat，不影响本次科学数据。

5. **MINOR CAVEAT — 解析错误经过同 attempt 纠正。** 位置：`run-03/run.log`。证据：局部 helper
   曾把 MATLAB 保留字 `otherwise` 用作形参，12.888699 s 后在进入任何 point 前解析失败；只把形参
   改名为 `fallback` 后 run-04 成功。后果：无科学方案变化，但 run-03 不能算数值证据。最小下一检查：
   保留失败日志并以 run-04 source snapshot 为正式源。

6. **已修复的上游 `BLOCKER` — BIE 矩阵与右端、场提取的密度坐标不一致。**
   公共源码缺陷已修复；当前阻断范围缩小为尚未重跑的 I7.2/I7.3 物理解释，不阻止归档修正前的
   程序、结果和失败证据，也不阻止 corrected I7.1 交付。
   源码证据如下（行号为本次核查时的位置）：

   - `+op/construct_A_QP.m:99-101` 对已经包含求积权重的离散矩阵进行左右平方根权重缩放：
     行乘 `sqrt(h*[speed,speed])`，列乘其倒数。这是密度坐标变换，不是补上缺失的求积权重。
   - `+bloch/incident_rhs.m:75-83` 返回未作上述缩放的入射值及法向导数；
     `+bloch/farfield_extractors.m:118-126` 使用 `h*speed` 求积权重，接收的是原始密度采样值。
   - 修正前快照 `run-13/construct_S-before.m` 直接用缩放后的 `A_QP` 解未缩放的 `rhs_all`，并把解
     直接交给原始场提取矩阵。现行 `+bloch/construct_S.m` 已改为右端同乘行缩放、求解后逆变换回
     原密度坐标再提取场；这不是改变物理入射条件。

   当前等角参数化圆的 `speed` 为常数，左右缩放在矩阵中抵消，因而该不一致可被圆形测试掩盖；
   中心椭圆的 `speed` 非常数，不能作同样抵消。加密 `ntot` 或 $M$ 不会自动纠正这种坐标不一致。
   三个冻结 $k$ 的 before/after 已证实它会实质改变四指标，并使 $d_H$ 从约
   $6.94\times10^{-3}$--$6.98\times10^{-3}$ 降至约
   $1.91\times10^{-13}$--$2.18\times10^{-13}$；corrected I7.1 也得到新的内点 dip。该证据仍不能
   断言坐标错误是旧跨离散平台的唯一来源。

   I7.1 的中心椭圆扫描/定位、I7.2 的端点计数及 I7.3 的加密检查均使用旧公共调用链。I7.1 已按
   修正路径重做；I7.2/I7.3 尚待各自重验。现有 I7.3 saved-data audit 只重算已保存矩阵及其下游坐标变换，未独立验证
   上游 BIE 密度与入射/场提取坐标的一致性，因此不会检出这一共享错误。此发现本身不证明原候选
   一定不存在，也不否定原始日志中的有限矩阵数值事实。

原审查“未发现 `BLOCKER`”的判断仍由 §D.6 对历史 I7.3 物理解释的限定取代；公共缺陷的源码修复
不能替代 I7.3 自身重跑，其余历史数值记录不回写。

## E. Implementation audit

对已保存匹配矩阵，下游坐标映射与比较约定内部一致，但不涵盖 §D.6 的上游 BIE 缩放检查：
$H=A_{\mathrm{def}}/T$ 的 $H_{\mathrm{sym}}$ eigenvectors 已在所组装的 physical
trace 坐标；$A_{\mathrm{phys}}$ 右 singular vector 通过 $q=D_cv$、$d=Tq$ 映射。跨 $M$ 比较按真实
$m$ 标签分别嵌入 left/right blocks，未比较不同维 raw coefficients。六条 hard edges 只比较同一
$k$、同一 operator。全部对象为 numerically simple（cluster ranks 均为 1）；若未来触发近简并，
代码保留 full basis 并使用 equal-rank principal subspace overlap。

run-04 的 saved-matrix audit 检查 18 个有效点和 18 个 hard comparisons：最大组装/右解组合残差
$7.25\times10^{-18}$，`Aphys` 重建相对差 $1.09\times10^{-16}$，物理迹重建相对差
$1.05\times10^{-16}$，四指标最大绝对差 $7.05\times10^{-18}$，overlap 最大差
$2.22\times10^{-16}$，tail 最大差 $3.50\times10^{-46}$。QZ、eig/SVD residual、warning、矩阵维数及
invalid count 均通过。Code Analyzer 的两条 advisory 是过期的 `%#ok<NASGU>` suppression 和用于维持
`onCleanup` 生命周期的 `warning_guard`；这是 run-04 源文件的静态结果，不是公式或运行错误。

调用链仍为 I7-local `LOCAL_cellsub`/`LOCAL_center` 调用公共 `kernel.precomp_proxy`、
`bloch.construct_S`，再经原 QZ 与 DtN 公式形成匹配对象；本阶段没有修改公共函数。现行源文件分为
一个入口、mandatory/local 各一个 saved-data audit 和 plot，以及一个资源 monitor。入口较长主要来自
点级 fail-closed 证据、完整 spectra/vectors 和同模态比较；两个 audit 都只处理各自保存数据，
plot 与 monitor 职责单一。local mode 仅在共享入口中增加显式分支：每点保留
primary/competitor 物理迹，每配置只保留一个
winner 的 full evidence；跨 $M$ 仍按实际 $m$ 标签分别对齐左/右墙。不同 $k$ 的 winner 被明确标为
`DIFFERENT_K_NOT_COMPARABLE`，本轮因六个 winner 恰为同一 double $k$，才进行跨配置物理迹比较。
无效点会使位置状态不可用，有限对象诊断失败会使 scientific outcome 为 unresolved。
未发现 forwarding wrapper、未执行的 `AUX` stage 代码或为少量重复建立的公共框架。

run-07 saved-data audit 重算 6 个 winner 的行/列权重、SVD 四指标、$T D_cV$
物理迹和 QZ 计数，并独立重算 66 条同 $k$ edge；四指标最大绝对差为
$7.05\times10^{-18}$，权重矩阵相对差 $1.09\times10^{-16}$，物理迹相对差
$1.05\times10^{-16}$，比较重算最大差 $3.33\times10^{-16}$。源程序 3 条 advisory 及 plot
1 条 advisory 都是过期 suppression 或 `onCleanup` 生命周期变量；audit 源程序无 advisory。

## F. What survived

| Config | (`ntot`, $M$) | $\min|\lambda_L|$ | $\min|\lambda_R|$ | $n_-:L\to R$ | `aphys_ratio(k0)` |
|---|---:|---:|---:|---:|---:|
| B | (256,48) | 1.02440899421342e-2 | 1.29547448112986e-2 | $0\to1$ | 3.03999932757942e-4 |
| M56 | (256,56) | 1.02440899421105e-2 | 1.29547448110740e-2 | $0\to1$ | 3.03999932758402e-4 |
| M64 | (256,64) | 1.02440899419460e-2 | 1.29547448112487e-2 | $0\to1$ | 3.03999932757942e-4 |
| N384 | (384,48) | 1.02440899418681e-2 | 1.29547448113482e-2 | $0\to1$ | 3.03999932757240e-4 |
| N512 | (512,48) | 1.02440899419651e-2 | 1.29547448110967e-2 | $0\to1$ | 3.03999932758481e-4 |
| J | (512,64) | 1.02440899419671e-2 | 1.29547448112805e-2 | $0\to1$ | 3.03999932759038e-4 |

- 三条 $c=50,100,200$ bands 在六配置全部给出相同 endpoint triples，unresolved 为零。
- 18 个 hard comparisons 的最小 primary overlap 为 `0.9999999999999998`，最大双向 competitor
  overlap 为 $4.50\times10^{-14}$；$|m|>48$ 最大 tail fraction 为 $7.44\times10^{-31}$。
- 最小 gap-to-cluster-threshold 比在 $H_{\mathrm{sym}}$ 对象超过 $8.31\times10^7$，在
  $A_{\mathrm{phys}}$ 对象超过 $8.32\times10^9$，故本轮没有依赖不稳定的单向量选择。
- 沿 `ntot` 轴，中心 `aphys_ratio` 的相对 range 为 $4.08\times10^{-12}$；沿 $M$ 轴为
  $1.51\times10^{-12}$；B 到 J 为 $3.61\times10^{-12}$。
- `adef_sigma` 沿 $M$ 轴稳定到 $1.71\times10^{-12}$ relative，但 `adef_ratio` 下降约 25%。这是
  增大 $M$ 后 $\sigma_{\max}(A_{\mathrm{def}})$ 从约 604.18 增至 805.24 所致，不能误称 dip 漂移。
- B 的 endpoint 组装、$d_H$ 与 $\eta_c$ 同 I7.2 完全一致，near-zero eigenvalue 只差
  $3.3\times10^{-13}$（L）和 $9.2\times10^{-13}$（R）；B 的中心四指标同 I7.1 最终保存点最大绝对差
  $1.1\times10^{-18}$。

local-only 网格为 $[1.7544553299700001,1.7545553299700003]$，公共步长 $10^{-5}$。

| Config | sampled winner $k$ | `aphys_sigma` | `aphys_ratio` | min adjacent ratio gap |
|---|---:|---:|---:|---:|
| B | 1.7545053299700002 | 8.69578027222250e-4 | 3.03999932757942e-4 | 3.64025397405138e-7 |
| M56 | 1.7545053299700002 | 8.69578027223564e-4 | 3.03999932758402e-4 | 3.64025397159621e-7 |
| M64 | 1.7545053299700002 | 8.69578027222249e-4 | 3.03999932757942e-4 | 3.64025396744697e-7 |
| N384 | 1.7545053299700002 | 8.69578027220243e-4 | 3.03999932757240e-4 | 3.64025398151395e-7 |
| N512 | 1.7545053299700002 | 8.69578027223789e-4 | 3.03999932758481e-4 | 3.64025396269870e-7 |
| J | 1.7545053299700002 | 8.69578027225385e-4 | 3.03999932759038e-4 | 3.64025396136025e-7 |

66 条跨配置同 $k$ 比较的最小 primary overlap 为 `0.9999999999999996`，最大双向
competitor overlap 为 $4.10\times10^{-14}$；baseline 与各配置在每个同 $k$ 点的重算 overlap
至少为 `0.9999999999999998`。各配置相对自身 $k_0$ 的网格端点 overlap 最小为
`0.9999999999947863`；这是物理迹连续性诊断，不是位置误差界。$|m|>48$ 最大能量份额为
$9.02\times10^{-32}$。

资源方面，run-04 entry runtime 为 340.255368 s，monitor wall 为 365.178545 s；3652 个 0.1 s
samples 的 task-tree 与 all-MATLAB 峰值均为 1,943,863,296 bytes，外来 MATLAB 记录为零。
加上 RSS 未知但保守计 1 s 的 run-01 和进入 point 前失败的 run-03（12.888699 s，峰值
886,259,712 bytes），mandatory 阶段 MATLAB wall 保守累计为 379.067244 s。monitor 自检及
preflight 拒绝没有启动 scientific MATLAB。资源监控在 run-04 使用 2.3 GB 提前终止线；该科学运行
完整结束而未触发终止。

local follow-up 中，run-05 在 5 个 point 后为纳入本审查提出的状态语义修复而主动停止，
wall 56.714003 s、峰值 1,298,055,168 bytes；它不是科学结果。正式 run-06 entry runtime 为
1236.527470 s，monitor wall 为 1250.057854 s，峰值 1,606,238,208 bytes；66/66 点完成，
外来 MATLAB 记录为零。run-07 saved-data audit/plot wall 为 13.889967 s，峰值
1,238,335,488 bytes。全部 I7.3 MATLAB wall 保守累计为 1699.729068 s，低于 2700 s；全局已知峰值
仍是 run-04 的 1,943,863,296 bytes，低于 3 GB，但 run-01 的早期 RSS 仍无法补记。

## G. Minimal resolution

原 mandatory 和 local-only 实验已经完成所列有限矩阵检查，历史结果保持不变；但 §D.6 使
“没有接受前必须修复项”不再适用于其物理解释。公共密度坐标和 I7.1 复验已经完成到 corrected
wide/local 阶段；I7.3 的最小后续仍是用现行公共路径重跑六配置 mandatory，再按新结果决定是否
需要 local-only 或 fresh `J--AUX`。I7.1 的成功不替代这一步，也不需要为此新增理论专题。

## H. Open-problem handoff

未决项只转交 [[research/projects/eig-apost/implementation/i7/README|I7 唯一问题表]]：I7-Q1 记录
有限扫描/连续位置边界，I7-Q3 记录 non-Hermitian $H$ 与诊断带边界，I7-Q4 记录本轮平台只覆盖
`ntot`/$M$ 而未识别 proxy/其他固定参数来源。当前审查不新建问题框架。

§D.6 初次补充审查时尚未获授权更新 README；现行 README 已在唯一问题表的 I7-Q5 记录密度坐标
错误、修复与受影响历史。I7-Q1/I7-Q3/I7-Q4 继续分别限制有限位置、Hermitian-part 代理和固定拟合
参数平台的解释；本文不另建问题框架。
