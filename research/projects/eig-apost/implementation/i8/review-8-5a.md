# I8.5 独立审查：两档空间离散、多 dip 搜索

## 审查范围与依据

审查对象为 [[research/projects/eig-apost/implementation/i8/design-8-5a|design-8-5a]]、
`test/i8/scan-v1/` 与本次 `output/attempt-1/run-01/`。问题是 coarse256／128 的33点
搜索窗口发现全部可见内部谷与端点来源后，fine512／256 的逐支细化能否交付可复核候选、
停止状态、缓存及耗时。成功不要求无遗漏连续谱认证，本轮没有谱距离评价。

Skeptic先读root/test/research AGENTS，核对设计、唯一配置、单点函数、manager和launcher，
只读对照I8.4源码的物理路径，不以旧结果作为真值。亲自检查setup-02/03人工测试、正式run的
config/state/requests/history/edge记录、两份终端MAT、资源CSV、status与失败记录，
并在MATLAB退出后独立执行 `audit_scan.py`，没有启动MATLAB。主代理按Skeptic给出的独立
driver保存审计源码并再次执行以落盘 `run-01/review/audit.json` 与 `command.json`；
这不是新的物理计算，也不计入搜索时间。

本文由主代理落盘Skeptic的审查结果。三名本轮新建代理均通过 `fork_turns="all"` 继承主线程
设置，未请求旧模型覆盖；工具没有提供独立运行时模型/effort遥测，不能把创建成功表述为遥测确认。

## Verdict

**PASS WITH CONDITIONS；无未解决 blocker。** 2927项搜索、配置、缓存、结果身份和资源检查
通过。唯一coarse内部dip获得fine处理并正常完成；coarse左端下降来源也实际进行了fine检查，
但到搜索边界仍未夹住。另保留3条非winner端点趋势，所以总体正确标为
`SEARCH_FINISHED_WITH_UNRESOLVED_INTERVALS`，不能声称整个窗口已经解决。

## 最强挑战与有界修复

最可能推翻交付的问题是在多谷或端点下降共存时只跟踪最低者、静默丢掉其他来源。
pre-run独审促成端点exact平台登记、恢复期间内部谷转为可追溯pending/child、终轮多可辨组
优先分支、子分支累计点按自身bounds过滤，以及非winner端点不冒称已覆盖等修复。
setup-03的11项便宜人工测试覆盖coarse单谷升档后分裂、两个粗谷、平台、端点恢复伴随内部谷、
失败保留、exact缓存和bypass。实际物理运行未出现可分辨fine分裂；第19和21轮各有3个微小
局部极小，按冻结阈值保留为歧义簇，没有宣称它们是同一连续模态。

## 原始证据重组

- coarse33点严格对应 `1.45+(0:32)*0.025`；第13点 $k=1.75$ 为唯一内部谷，
  原邻界 $[1.725,1.775]$、fine扩窗 $[1.7,1.8]$。左端来源以 $[1.45,1.525]$ 实际fine采样。
- 正常分支完成21轮，末轮11节点严格递增、首次argmin为第2节点，
  $W=4.218847493575595\times10^{-15}$。正式和累计最佳均为 $k=1.7562818500073423$。
  第20轮 $W=2.0872192862952943\times10^{-14}$ 尚未达标且评分略回升，仍继续到第21轮，
  没有以小指标、单轮停滞或回升提前停止。历史candidate没有参与搜索输入、居中或停止。
- 277请求=221实际计算+56缓存命中。coarse33个不同 $k$；fine搜索242次请求、186个不同 $k$，
  再加2次bypass，共188次fine调用。完整配置、档位与binary64位模式逐项核对，未用十进制截断合并。
- 每点两次proxy回调、每次320源；coarse目标数16384/65536，fine65536/262144，
  所有FMM `ier=0`。没有混用空间档位或额外密度缩放。
- 两份终端MAT均保存fine几何512/256及194×194匹配矩阵。独立从散射块与QZ子空间重组DtN、
  $A_{\rm def}$、$A_{\rm phys}$，正常候选后两者相对Frobenius差为
  $2.9204\times10^{-16}$、$2.8209\times10^{-16}$；边界点为
  $2.7678\times10^{-16}$、$2.7046\times10^{-16}$。
- 独立NumPy SVD与MATLAB保存指标之差：正常候选 `adef_sigma` 为 $9.6459\times10^{-16}$，
  `aphys_sigma` 为 $7.0539\times10^{-17}$；边界点分别为 $1.68754\times10^{-14}$、
  $8.88178\times10^{-16}$。不同浮点线性代数实现无需逐位一致，近零指标以绝对差为主。
  原MATLAB绕过缓存重新调用的四指标，两份终端记录均全部绝对差为0。
- 互斥点时间为coarse32.92858625秒、fine搜索423.3926144583秒、复算4.6582472917秒，
  合计460.979448秒；完整进程480.4408752089秒。其余19.4614272089秒包括管理、保存、绘图与启停，
  不再和proxy子计时重复相加。峰值采样process-tree RSS为1,225,981,952 bytes，低于3e9；
  exit0、采样无其他MATLAB、无残留，未使用soft门延长。

## Findings与解释边界

1. **Important caveat：覆盖尚未闭合。** 左边界窗口未夹住；3条非winner趋势分别为内部谷第20轮
   左端 $1.7562818500073252$、第21轮右端 $1.756281850007346$、边界检查右端 $1.525$。
   它们不是额外已定位模态，也不能表述为没有dip。初始 `FINE_ENDPOINT_CHECK_PENDING` 是历史事件，
   最终去向由interval2的 `BOUNDARY_UNRESOLVED` 给出。当前交付为1个正常候选加1条边界暂存记录。
2. **Important caveat：歧义规则是工程判据。** $64\,\mathrm{eps}\max(1,\max|y|)$
   只防止舍入起伏导致无限分支；全部极小、saddle与分组保留，不证明同模态或给出误差界。
   实际末轮宽度满足用户门槛，但不等于连续谱位置误差。
3. **Important caveat：粗网格可能遗漏窄谷。** 本次可见谷升档后保留；粗节点1.75到fine首轮1.76的
   变化同时改变采样网格，不能单独解释为离散导致的谷移动。未做完整双档曲线、收敛、惯性或谱距离，
   不构成本阶段blocker，也不支持整个搜索窗口或projected gap的无遗漏主张。
4. **Minor caveat：资源与性能为一次本机观察。** RSS以1秒采样，不能证明任意瞬间连续峰值；
   R2023b/MACA64、MATLAB11线程、OpenMP11/FALSE已记录。进程余项未进一步拆分，不外推普遍加速倍数。

## 通过项、失败记录与交接

六职责分离、唯一参数来源、fine专属候选、exact缓存、所有粗来源去向、原匹配路径和bypass复算可接受。
setup-01是MATLAB启动前 `ps` 被sandbox拒绝及finally重复失败，原command/failure记录保留；
同attempt的setup-02/03分别成功完成自测，正式run-01没有科学失败或重跑。
Conda环境缺NumPy的只读检测后，审计使用已有bundled Python，没有安装依赖。

正式运行后仅修正三处异常/状态记录逻辑：异常不覆盖最新checkpoint，复算失败阻止总体成功标签，
global端点事件使用正确说明。主代理静态核对 `postrun-repair.patch` 与执行源码快照，成功运行的
数值路径和原始记录均未变；这些修复没有追加MATLAB验证或科学重跑，不将未触发异常分支称为实测通过。

无需追加物理实验。独审证据在 `output/attempt-1/run-01/review/`，重要/次要限制登记在
[[research/projects/eig-apost/implementation/i8/README|I8问题账目]] 的I8-M1/M2。
**本轮没有计算 $C_{\rm num},\varepsilon_{\rm num},U_{\rm num},R_{\rm num}$；不自动进入谱距离阶段。**
