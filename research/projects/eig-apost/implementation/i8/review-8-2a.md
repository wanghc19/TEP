# I8.2：五配置固定点检查独立审查

## A. 审查框架

审查对象是 `check_i8(k0,halfwidth)`、正式 run-01 的原始矩阵和诊断、以及独立
`audit_i8(result,evidence)`。本阶段属于数值案例研究：在
$k_0=1.7562818500073463$ 和肩宽 $10^{-5}$ 上，检查五个规定离散配置是否保持相同的
Hermitian-part 端点计数变化及 physical-trace 模态。成功标准不是连续谱认证、位置收敛或 raw-$H$
惯性证明。

核查材料包括 [[research/projects/eig-apost/implementation/i8/design-8-2a|设计]]、
`test/i8/check-v1/check_i8.m`、`test/i8/check-v1/audit_i8.m`、run-01 的
`scientific.mat`、`result.json`、`points.csv`、解析路径和资源记录，以及 run-02 的
`audit.json`。I7.2/I7.3 只用于核对公式与坐标约定，不作为本轮数值输入。

## B. 判定

**PASS WITH CONDITIONS（高置信度）**。没有未解决程序 blocker。十五个点均有效，端点三档计数、
两条加密轴的同模态比较和独立矩阵重组均通过。条件是：中心的 Hermitian-part 符号仍 unresolved，
微小奇异值指标没有显示单调离散收敛；因此本轮只支持规定五配置上的固定点同模态和端点计数稳定。

## C. 最强挑战

最可能被过度解释的是“同模态”与“数值幅值收敛”的混同。五个中心都在
$c=50,100,200$ 三档中有一个 unresolved eigenvalue；中心 `aphys_ratio` 从基线到 `N512`
相对变化约 $15.24\%$，而 $d_H$ 也不随加密单调下降。同模态证据表明比较的是同一物理迹对象，
但不把这些微小量升级为已收敛数值、中心符号或连续特征值。该限制不阻止当前固定点检查交付。

## D. 审查发现

1. **IMPORTANT CAVEAT — 中心符号未解析。** 五配置中心计数均为
   $(2K-1,0,1)$，最近零特征值绝对值为 $1.22\times10^{-14}$ 至
   $1.45\times10^{-13}$，明显落在相应 $\eta_{50}$ 内。程序将其单列为
   `SURROGATE_SIGN_UNRESOLVED`，没有用中心计数冒充端点 jump。影响限于中心符号、raw-$H$
   惯性和连续根解释；当前阶段无需扩大肩点。

2. **IMPORTANT CAVEAT — 微小指标未证明收敛。** 相对基线，`N384`/`N512` 的
   `aphys_ratio` 分别变化约 $4.79\%$/$15.24\%$；`M56`/`M64` 分别约
   $3.78\%$/$1.20\%$。`adef_ratio` 还受最大奇异值随 $M$ 改变影响，不能跨维数单独当作模态
   漂移。若后续论证依赖 dip 深度而非同模态身份，最小后续检查是增加独立的空间离散轴并重新定位；
   这不是本轮完成门。

3. **IMPORTANT CAVEAT — 覆盖范围是两条指定轴。** `nside=ntop=160`、`nproxy=80`、
   `mpw=32` 固定，故结果不是全离散收敛证明。该范围与用户冻结合同一致，已移交项目 README 的
   I8-Q3/I8-Q8，不需要本轮扩展参数搜索。

4. **MINOR CAVEAT — Code Analyzer 提示不影响结果。** 唯一提示来自保留
   `onCleanup` 生命周期的 warning guard；正式运行后只增加了抑制注释，没有改变可执行计算。

## E. 实现与数值审计

- 五配置严格为 `(ntot,M)=(256,48),(384,48),(512,48),(256,56),(256,64)`，其余配置固定；
  三点是同一 binary64 运算得到的 $k_0-h_k,k_0,k_0+h_k$。
- 中心公共 star 的六行数据统一乘 $\sqrt{0.04/0.0618}$；lead 保持半径 $0.2$ 圆。
  两者均使用修正后的公共 `bloch.construct_S`，实验没有重复密度缩放。
- 每点从四个中心散射块独立构造 $A_{\rm def}$，并检查
  $A_{\rm def}=N_0-LT$；实际使用 $H=A_{\rm def}/T$，没有对 $A_{\rm def}$ 直接取
  Hermitian part。十五点最小 `rcond(T)` 为 $0.5169929844$，最大 assembly/solve 归一化残差分别为
  $1.09\times10^{-18}$ 和 $5.96\times10^{-19}$。
- QZ 在所有点、两个方向均为 $K/K/0/0$；无失格子空间被强行提取。三档
  $\eta=d_H+cn\epsilon_{\rm mach}\max(1,s)$ 和完整计数均保存。
- 中心模式用 $A_{\rm phys}=D_rA_{\rm def}D_c$，再恢复
  $q=D_cv$、$t=Tq$。跨 $M$ 比较分别按真实 $m$ 标签嵌入 left/right blocks；全部目标 cluster rank
  为 1，故使用 phase/scale-invariant primary 和双向 competitor 比较。
- 独立 run-02 审计不是读取汇总 verdict：它从保存的 lead/center blocks 重建 pencil、DtN、
  $T,N_0,L,A_{\rm def},H,H_{\rm sym}$，重算 eig/SVD、三档计数、权重、$Tq$、12 条主 edge 和
  4 条基线 center 比较。覆盖为 15/12/4，最大差异
  $1.1619553924721235\times10^{-14}$；pencil 至 eta 的九类缺陷均为零。

## F. 经受核查的结论

五配置三个 band 的左肩均为 $(2K,0,0)$，右肩均为 $(2K-1,1,0)$，所以每配置内部
$(\Delta n_+,\Delta n_-,\Delta n_0)=(-1,+1,0)$；端点没有 unresolved。十二个主同对象比较全部
`SAME_MODE`，最小 primary overlap 为 $0.9999999999999997$，最大 competitor cross-overlap 为
$2.325126673691677\times10^{-5}$。四个基线 center 直接比较也全部通过。基线中心四指标与 I8.1
最终同点值逐位一致。

正式入口 runtime 为 $244.3254000417$ 秒；run-01 wall time 为 $270.179383$ 秒。含独立审计的累计
监控时间为 $293.254261$ 秒，峰值进程树与 MATLAB union RSS 为
$1{,}083{,}080{,}704$ bytes；没有并发或资源超限。

## G. 最小闭合与下一步

本轮无需数值修复。将项目状态更新为 I8.2 完成，并保持“有限维 Hermitian-part 计数与同模态稳定”
的措辞即可。若启动 I8.3，必须在这个新候选上重新构造冻结场和完整分项；旧 I8.3 数值不得继承。

## H. 问题移交

未解决但不阻断的问题仅链接到
[[research/projects/eig-apost/implementation/i8/README|项目问题表]]：I8-Q3 记录两轴固定点检查不等于
全离散或位置收敛，I8-Q6 记录新候选的 I8.3 尚未执行，I8-Q8 记录中心微小量和非单调幅值。没有新增
独立问题表。
