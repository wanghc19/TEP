# I8.4：direct 与 FMM 独立全流程审查

## Material Passport

- Review object: `design-8-4b`，不是旧第二阶段 `review-8-4b`
- Origin: `academic-research-suite / independent Skeptic review`
- Date: `2026-10-21`
- Verdict: **PASS WITH CONDITIONS**
- Verification: `CURRENT RAW DATA AND CODE INDEPENDENTLY RECONSTRUCTED`
- Claim boundary: `UNCERTIFIED_RNUM; OBSERVED INDEPENDENT PIPELINE COSTS`

**没有未解决 BLOCKER。两条完整数值流程成立，结果保持 UNCERTIFIED_RNUM。**
Skeptic 提供本审查判断与正文，主代理负责落盘，不将工程摘要替代独立检查。

## A. 范围、依据与判定

审查对象为 [[research/projects/eig-apost/implementation/i8/design-8-4b|独立全流程合同]]、
`test/i8/pipeline-v1/` 新实现、运行源码快照，以及 `output/run-02/` 两后端的实际节点、
批次日志、资源记录和 `estimate/scientific.mat`。旧任务候选与结果不作为本次执行证据。
目标是比较同配置和规则下，各自重新搜索、构场和评价的普通数值流程；不要求连续位置误差界或谱认证。

父代理保存审计脚本和原始输出后，Skeptic 亲自完整只读执行两个脚本。
搜索/资源审计 exit 0，**8122项检查通过**，与持久化JSON逐项相同；
raw审计 exit 0，除运行时间外与持久化JSON相同。Skeptic 未启动MATLAB、安装依赖或修改科学数据。
随后亲自重算材料矩阵作用及完整有限段/尾项，检查消去敏感性；代码与输出亦已保存。

置信度高，限于本次工程数值交付。两后端各242次搜索加一次fresh构场、唯一768评价、
正分母和完整计时账目均有证据。最可能推翻交付的历史候选复用、跨后端场混用或实际网格错误，
经源码和逐点记录检查未发现。每点两个field callback均为320源、65536/262144配对目标，
支持从宽扫第一点采用lead256/center512；与某历史数值相同不能单独证明复用。

## B. 搜索与主结果

| 项目 | direct | FMM |
|---|---:|---:|
| 搜索评价数 / distinct $k$ | 242 / 188 | 242 / 188 |
| 累计候选 $k_*$ | 1.7562818500073463 | 1.7562818500073423 |
| 候选首次evaluation index | 240 | 229 |
| 最终内点索引 | 9/11 | 6/11 |
| 最终实际整轮 $W$ | 1.3322676295501878e-14 | 相同 |
| 最终邻点宽度 $w$ | 2.6645352591003757e-15 | 相同 |
| 保存的 $R_{\rm num}$ | 7.0521608619273654e-10 | 7.0632274130478178e-10 |

均为33点宽扫加19轮11点细化，无recovery，无平台或小奇异值提前停止。
每边54次重复位置评价的四指标逐位一致；fresh构场四指标与各自候选逐位一致。
FMM累计候选首次出现于第18轮，末轮仍选相同位置，不应把首次出现写为第19轮。
完整实际间距由保存节点重建；$W,w$及相邻步长均未当作位置误差界。

候选绝对差为 $3.9968028886505635\times10^{-15}$；保存主值差约
$1.10665511204523\times10^{-12}$。以direct为分母约 **0.156924%**，
以两者较大绝对值为分母约 **0.156678%**，两种口径不可混用；两场质量也并非逐位相同。
主表的相对差用 `relative_to_direct`。除明确标明分母的量外，独审脚本 `rel` 使用
$\|a-b\|/\max(\|a\|,\|b\|,10^{-300})$。

## C. 原始矩阵、场与标量

两后端center/lead geometry分别为 $6\times512$、$6\times256$，matching为
$194\times194$，评价为768节点、2048个disk积分样本。
独立重建 $T,N_0$ 差为零，$A_{\rm def},A_{\rm phys}$ 相对Frobenius差不超过
$3.03\times10^{-16}$；归一化、密度与FFT插值差为普通舍入量级，$q$方向一致。

由center signed样本、保存的逐cell能量行与tail、center-wall样本和disk样本重组的
$E_v,E_n$ 相对差不超过 $2.86\times10^{-16}$；独立重算
$C,\varepsilon,U,Q,D,R$ 与保存值仅有舍入差异，两个分母均为正。
检查的是每条pipeline内部自己的冻结场，没有跨后端混用任何标量或密度。

微小分项并不具有普遍高相对精度：

- center raw action跨BLAS重算最大绝对差约 $5.60\times10^{-15}$，整体相对差约0.17%。
- lead raw action最大绝对差约 $1.94\times10^{-14}$、$2.07\times10^{-14}$，整体相对差约52.12%、49.97%。
- center value平方重算相对变化约47.73%、44.72%，绝对变化仅约 $6.82\times10^{-30}$、$6.15\times10^{-30}$。
- 基于保存lead signed actions重算的有限cell行保持舍入一致；wall有限行整体相对差最高约0.07255%，tail向量最高约0.02377%。整体范数差不是逐分项误差上界。
- direct的 $A_{\rm def}$ 最小奇异值，NumPy重算约 $1.58673\times10^{-13}$，MATLAB保存约 $8.88667\times10^{-14}$；绝对差约 $6.98\times10^{-14}$。近零SVD指标跨BLAS相对敏感，不能解释为高相对精度的残差证据。

Skeptic另作有界运算次序检查：重新计算材料raw matrix action、center-wall及41项传播收缩，
再组有限段与观察tail，保留原 $C,U$，得到

$$
R_{\rm matrix,direct}=7.052090309240172\times10^{-10},\qquad
R_{\rm matrix,FMM}=7.063145991130383\times10^{-10}.
$$

相对各自保存主值分别变化 $-1.00044\times10^{-5}$、$-1.15276\times10^{-5}$。
该检查显示本次完整标量对这一运算次序扰动影响较小，同时揭示微小分项消去敏感性。
它不是高精度参考，不替换主结果，不形成误差界，也不是第三条科学pipeline。

## D. 时间、资源与实现记录

| 成本（秒） | direct | FMM |
|---|---:|---:|
| 搜索point合计 | 4706.354323 | 544.078151 |
| fresh最终构场 | 20.738638 | 2.356218 |
| 完整jumps | 182.943271 | 28.238567 |
| mass | 77.673579 | 13.155118 |
| geometry/assembly | 2.237217 | 2.140965 |
| 保存/导出 | 2.928558 | 2.769540 |
| 其他进程成本（含启停/包装） | 386.562222 | 287.518972 |
| **成功进程批次wall合计** | **5379.437807** | **880.257531** |
| 后端controller elapsed（另一边界，不加至上表） | 5379.567750 | 880.366573 |

账目重组一致，callback只作所属阶段子项。成功批次wall比 **6.111209**，
是本机一次direct先行、FMM后行的实测流程成本比，不是普遍加速保证。
两边点数相同；小尺度实际节点/评分不同，已分别保留。

共同setup 13.735072秒；中断配置bootstrap 10.488923秒，尚未计算科学点。
全部批次成本6283.919333秒，失败未被隐去；54份状态中仅该bootstrap未成功。
无grace，最长批次302.409803秒，采样process-tree RSS最大1,616,920,576 bytes，低于3 GiB。
清理无残留，监控未见外部MATLAB。每后端601次callbacks，其中最终估计117次，FMM全部 `ier=0`。
本次未使用resume。MATLAB R2023b/MACA64，MATLAB/OpenMP均11线程，`OMP_DYNAMIC=FALSE`。

启动快照与后续源码差异已查验：几何邻胞元位移由 $\pm1$ 改为 $\pm L$，冻结 $L=1$，
搜索不执行该helper；另一变化只在计时前导出环境元数据，不改变科学结果。
控制器后续防御性改动未被本次活跃启动进程使用，需以启动快照解释本次执行。
父代理最终只读 `ps` 在沙箱内权限失败，随后获准重查确认MATLAB为零；记录于审计日志，无科学重跑。

独立Python审计与MATLAB成本分开：Skeptic亲跑搜索约0.219秒、raw约1.354秒，
raw子进程峰值RSS 1,401,503,744 bytes；矩阵运算次序检查约1.4秒。
父代理持久化重放的实际命令、退出码与时间另见 `review/commands.json`，不计入成功pipeline速度比。

## E. 问题分级与关闭决定

| 等级 / 账目 | 限制及影响 | 当前处理 |
|---|---|---|
| **BLOCKER** | 无未解决问题 | 可关闭本次完整数值对照 |
| **IMPORTANT / I8-Q2** | 有限扫描可能漏分支；sampled geometry、求积、MFS及观察tail无单侧误差控制 | 保持UNCERTIFIED_RNUM；不升级为可靠上界或位置收敛 |
| **IMPORTANT / I8-E2** | 微小material/wall消去及近零SVD相对敏感 | 有界全账目矩阵重组已完成；不声称所有分项相对稳定，不追加科学运行 |
| **IMPORTANT / I8-PL1** | 两候选及两场不同，差不是单独FMM核误差；单次固定顺序时间不足以推广普遍倍数 | 报告本次成本及独立场差异；更强归因或性能推广属于未来另行授权任务 |
| **MINOR / I8-PL2** | 未存逐批绝对UTC，前三宽扫批次缺新增environment JSON，源码存在已解释元数据/等值更新 | 相对时间、命令、后续环境、串行控制与资源足以支持本次；不得从mtime伪造UTC区间 |

三方新建代理的工具调用明确请求 `gpt-6-astra / high` 且获接受；没有运行时模型遥测，
不能将创建参数记录说成运行时身份验证。此项已披露，不影响原始数值证据。

上述问题登记在 [[research/projects/eig-apost/implementation/i8/README|I8唯一问题账目]]，
不额外建立状态或问题目录。未认证、未证明收敛及未运行额外对照均不是本轮blocker。
本阶段关闭，不进入新的敏感性、扫描或认证实验。

## F. 可复核证据

- `test/i8/pipeline-v1/output/run-02/` 下的 `summary.json`、`summary.csv`、`rounds.csv`、`components.csv`、`callbacks.csv`：生成的汇总记录，按 output 规则忽略；关键结果保留在 README 和设计文档中。
- `test/i8/pipeline-v1/output/run-02/{direct,fmm}/`：原始逐点、逐轮、MAT、命令及资源。
- `test/i8/pipeline-v1/output/run-02/review/`：`search-resource-audit.json`、`raw-audit.json`、`matrix-order-audit.json`、命令与失败日志。
- `test/i8/pipeline-v1/{skeptic_search_audit.py,skeptic_audit.py,skeptic_matrix_order.py}`：仅依赖本目录、当前输出及已安装NumPy的独审代码。
- `output/run-01/`与`output/attempt.json`：同一logical attempt的中断bootstrap与恢复记录。
- [[test/i8/pipeline-v1/README|从零运行及后处理说明]]。
