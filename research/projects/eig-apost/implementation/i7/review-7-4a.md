# I7.4：中心椭圆谱距离评价与认证审查

## 范围与审查方式

2026-10-06，Researcher、Engineer、Skeptic 实际协作；Skeptic 独立只读审查，主代理记录本报告。
工作树为 `epost`、分支 `codex/epost`，起点工作区干净。只修改 I7.4 新实验、指定设计/审查及
I7 README；main、旧实验和公共包只读，不 commit/push。

rigorous-proof 模式为 **Review only**：核对既有
[[research/projects/eig-apost/phase3-analysis/resolvent-bound/s-trace|T9--T10]]、
[[research/projects/eig-apost/phase3-analysis/resolvent-bound/s-framework|F14]]，
及 [[research/projects/eig-apost/implementation/i6/design-6-1c|I6 的精确输入与球算术合同]]
在当前 raw 场上的适用条件。旧证明未修改；本轮没有另立连续特征值认证定理。
当前实验的适配与符号见 [[research/projects/eig-apost/implementation/i7/design-7-4a|设计]]。

## 实现前审查

Skeptic 确认 I6 的圆形材料求积、圆形墙提取及空中心质量公式不能只替换参数。
椭圆必须采用实际弧长权重、普通外法向、曲率和分离条件，并重新评价中心 singleton。
椭圆弦长分解多出依赖两参数平均值的光滑因子，旧圆形 local/Kress 连续余项不能自动复用。

密度约定为 `eta=[tau;zeta]`、`zeta=-sigma`，外部散射场为
$D_e^{\mathrm{qp}}\tau-S_e^{\mathrm{qp}}\zeta$，内部场为 $D_i\tau-S_i\zeta$。
中心材料普通法向跳跃必须保留第二块的恒等项：

$$
j_0=-\left(B_Nq+
\left[T_e^{\mathrm{qp}}-T_i,\ I+D_i^*-D_e^{\mathrm{qp},*}\right]\eta_0\right).
$$

Researcher 的初始简报省略了该 $I$，在实现和计算前经主代理与 Skeptic 交叉核对更正。
没有以范数不看整体符号为由省略恒等项。原公共 `construct_A_QP`、`incident_rhs` 和
`farfield_extractors` 是该核对的源码依据，公共文件未改。

有限边界节点的点源和不能直接冒充光滑 raw 层势。冻结密度须明确给出连续有限三角表示，
然后作用于完整精确准周期核；求积及核截断只是评价该对象，不据此把未验证的实际缺陷设零。
材料界面、两条中心墙、内部墙、无限胞元和遗漏墙模态须分别记账。

## 标量球算术的范围

`certify_scalars_i7.py` 复用 I6 的 Arb 端点序列化，重新计算冻结 binary64 $k_0$ 的精确实平方，
椭圆/圆共同 collar 常数及 F14 标量组合。Skeptic 要求并已加入冻结模型门，避免将布局依赖的
距离公式用于任意 JSON 几何。标量脚本始终区分数值输入与已认证单侧输入；把浮点估计外舍入
不会使它成为连续跳跃上界或质量下界。

已核对 [python-flint 的实球与定向端点接口](https://python-flint.readthedocs.io/en/latest/arb.html)
及 [数值包含性说明](https://python-flint.readthedocs.io/en/latest/general.html#inexact-numbers-and-numerical-evaluation)。
这属于软件原语合同，未声称形式化验证库或硬件。没有新增外部书籍定理引用或下载文献。

## 运行与最终判定

`attempt-1/run-01` 正常退出，但材料界面评价被审查否决。双侧离面求积及两点外推在
256 到 512 节点之间仍有 $0.9306$--$0.9984$ 的分项相对变化；得到
$\varepsilon_{\rm num}=0.762146950984352$ 和负分母 $-2.06804062383803$。
这不是候选不存在的证据，而是近奇异离面求积未分辨。该次完整 MAT、脚本快照、日志及
222.778350 s / 1,088,667,648 bytes 的监测记录保留，不用于最终谱距离解释。

定向修正保持 raw density、候选和所有物理参数不变，改为调用公共
`op.construct_A_QP` 的边界极限作用：对同一 256 点物理密度插值到评价节点后，使用
$D^{-1}A_sD\eta+B$，第一块为值跳跃、第二块取负为普通法向跳跃。
没有重新求解加密后的密度。Skeptic 核对了缩放、identity 和符号，并指出 256 点残差按构造近零，
故 256/512 相对差不能冒充收敛率；应报告加密后绝对缺陷及其数值尺度。

球算术另以形状通用的正距离 Rayleigh 系数界包围所有墙的 $|m|>48$ 模态。
中心使用冻结密度的离散 Parseval 上界，lead 使用冻结 $H,G_\pm,c_\pm$ 的范数与完整
$P_\pm$ 收缩界；内部墙由 $(1+r_\pm)^2/(1-r_\pm^2)$ 合并无穷序列。
Researcher 与 Skeptic 独立核对系数、模态两侧因子及求和。这项单列，不重复加到已采样完整墙函数的
普通范数中；保留模态误差、材料连续余项和质量下界未因此获得认证。

`run-02` 为同一修复过程中主动中断的运行：为了让 $D$ 严格来自传给公共 BIE 的同一 $C$，
Engineer 发出 Ctrl-C；监控当时的 `ps` 子进程记录 SIGINT，exit 130。
事后 live 检查确认其 MATLAB 进程已退出、没有并行 MATLAB。最后保存的 `ps-current.txt`
只是中断前快照，未被误作进程继续存活的证据。耗时 17.606960 s，峰值 978,190,336 bytes。

`run-03` 正常完成正确边界极限评价，材料法向平方和约 $2.59\times10^{-28}$，
墙面法向平方和约 $1.02\times10^{-20}$。此时使用 sampled mass candidate 得到的条件数值
$1.5586126805507365\times10^{-8}$ 只作过程记录。`run-04` 对本任务已冻结的 raw 数据补做
Rayleigh/Arb 安全盘质量认证，得到更保守且严格的 $\underline U=0.08973136188400639$。
读取本任务显式冻结数据不用于改变模型；最终复现入口已另作完全 fresh 验证。

`run-05` 是正式结果：从当前公共代码重新构造矩阵和 raw 场，再执行独立审计与全部现有 Arb 分项，
没有读取历史数值产物。普通跳跃评价为
$\varepsilon_{\rm num}=1.0116161391167468\times10^{-10}$，
$\overline C=2.863846920155989$。用严格质量下界组合得到

$$
D_{\rm num}=0.08973136159429502>0,\qquad
R_{\rm num}=1.991123525767936\times10^{-8}.
$$

参考区间约为 $[3.0835210220599048,3.0835210618823754]$，**不是已认证谱包含区间**。
该正分母是对数值跳跃输入的条件组合，不是对尚未知的连续跳跃上界所作证明。

## 独立验收与未关闭项

Skeptic 指定并审查了 `audit_i7_resolvent.m` 的独立重组清单。run-05 实际从 fresh 完整矩阵重组
$T,A_{\rm def},A_{\rm phys}$、权重、SVD 选定的 $q$、四指标、$G_\pm,P_\pm,c_\pm$ 关系、
原始坐标材料 action、signed wall 范数与完整分项，以及 JSON 和冻结数据的对应。
`all_pass=true`，最大归一化差 $2.343066857381263\times10^{-13}$，预设阈值 $10^{-11}$。
该审计是实现一致性检验，不能包围连续求积误差。

Skeptic 还逐式核对安全盘的 exact-QP Rayleigh 系数、256 点密度 Nyquist 平分约定、512 点源梯形余项、
复带非零速度分支、全部 $|m|>48$ 点值/梯度尾及整个圆盘的梯度界。使用
$v(z)^2=c-d\cos(2z)$、$|\cos(2z)|\le\cosh(2\alpha)$ 得到的速度带宽上界有效；
不是以 sampled gradient 最大值代替连续上界。正式质量证书的点值下界、梯度上界和锥余量分别约为
$1.04770791346249$、$3.80319869411715$ 和 $0.810007995080169$。

| 对象 | 审查结论 |
|---|---|
| 精确 $\mu$、曲率/reach/collar 分离与新 $\overline C$ | Arb 与解析几何条件通过 |
| 完整 $P_\pm$ 收缩、连续 raw 场结构上的分片 PDE/QP/$L^2$ | 通过；PDE/QP 使用定义中的 exact kernels，未把 MFS 残差设零 |
| 全部墙遗漏模态尾、同一保存密度定义的安全盘质量下界 | 单侧认证通过；没有和物理墙采样重复计入 |
| 普通材料/墙分项、经验胞元尾、F14 数值组合 | 正常完成，独立实现审计通过 |
| 完整连续 $\overline\varepsilon_\partial$、有限的严格谱距离上界 | **未建立** |

中心保存密度与普通 action 中 `Hmap*q` 的浮点乘积差约 $2.17\times10^{-16}$。
它是同一冻结场数值评价的未包围舍入误差，不能当成 exact identity；连同材料连续核/求积、
保留墙模态评价和完整 action 尾，一并阻止将 $R_{\rm num}$ 升级为严格距离界。

Researcher 的剩余工作评估具体落实到 I6 的圆形专用 `local_factor_bounds`、`local_split`、
`local_centers` 和 `regular_bounds`：需要 general-ellipse 双参数几何、$\log g$、对角极限、
连续 strip 与 Kress/Bessel/Ewald 余项的球算术适配。公共 double 节点矩阵不能替代这些半径。
该移植及独立审查无法可靠纳入剩余任务时间，因此停止新增实现，交付明确未认证的实际评价。

最终判定为 **PASS WITH CONDITIONS（数值实现与已列明的部分证书）**；
**完整连续谱距离认证尚未完成**。
不从较小 $R_{\rm num}$ 推出已认证连续谱点、离散性、实根、唯一性、模态编号或谱隙结论。
六次串行受监测调用（含失败修复和报告导出）累计 $628.251433$ s，
进程树峰值 RSS 为 $1{,}209{,}221{,}120$ bytes；提前终止门为 $2.3$ GB，
累计计算少于 $1800$ s，未越过 $3{,}000{,}000{,}000$ bytes 硬上限。
正式运行与完整资源记录见 [[test/i7/resolvent-v1/README|实验 README]]。

未闭合事项统一登记于 [[research/projects/eig-apost/implementation/i7/README#I7 待办与问题|I7 问题表]]，
不以本节的实现前审查代替实际计算或最终验收。
