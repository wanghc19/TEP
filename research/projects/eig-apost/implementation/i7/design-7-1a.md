# I7.1 中心椭圆与自适应扫描设计

## 1. 问题、成功条件与权威

- Design ID: `I7.1-ELLIPSE-SCAN-V1`
- Stage: `FROZEN MODEL/SCAN; SCHEME-2 KERNEL PATH VALIDATED`
- Question: 在 fixed-$\beta$ 圆形周期 half-guide 的数值 projected gap 内，把中心圆柱改为等面积
  椭圆后，冻结 final 空间离散所计算的 `aphys_ratio` 在已覆盖网格上的最小有效点是什么？
- Success criterion: 至少一个 final 配置点完成有效评价，并保存同一 $k$、同一组
  $A_{\mathrm{def}}$ 与 $A_{\mathrm{phys}}$ 产生的四个标量及完整扫描记录。dip 浅、没有明显
  内点 dip 或边界最小都不构成失败；这时交付物称“当前扫描最佳点”。

数值代码以 main 参考提交 `54eeb12b8223e6dcb6a5b91d3e2ccb3c12b564eb` 的
`draft/examples/projgap.m` 和 `draft/examples/betagmode.m` 为直接基准。scattering block 的接口与
端口约定由同一提交的 `+bloch/construct_S.m` 支配。项目解释参考
[[research/projects/eig-apost/implementation/i2/README|当前 I2 状态]]：I2.2 采用
$H_{\mathrm{sym}}$ sign count 作数值佐证，I2.3 的零 observed drift 只表示保存的同模态 candidate
未发生可见漂移。

本轮不开展严格 Hermitian 证明、严格 projected-gap 认证、完整谱搜索、材料参数搜索或新的理论
专题。I7.2 只在 [[research/projects/eig-apost/implementation/i7/README|I7 README]] 中规划。

## 2. 冻结模型与两类离散

物理模型为

| Quantity | Value |
|---|---:|
| $\beta$ | $0.5$ |
| period $d$ | $1$ |
| $X_L,X_R$ | $-0.5,0.5$ |
| all-inclusion `epsrel` | $17$ |
| half-guide inclusion | circle, radius $0.2$ |
| center inclusion | ellipse, $x/y$ semi-axes $0.25,0.16$ |
| proxy height/distance | $1.1,0.2$ |

椭圆面积为 $\pi(0.25)(0.16)=0.04\pi$，等于半径 $0.2$ 圆的面积。中心形状通过
`geom.construct_cont(...,flag_geom,...)` 的 `flag_geom='ellipse'` 和轴参数构造；half-guide 的
`LOCAL_cellsub` 始终使用 `flag_geom='circle'` 和半径 $0.2$。两者都使用
$k_{\mathrm{int}}=\sqrt{17}\,k$。

必须区分以下对象：

1. **$k$ 采样网格**决定扫描覆盖和定位分辨率；
2. **空间离散配置**决定每个点的边界、proxy 与 Rayleigh 离散。

main `betagmode.m` 中的 `coarse`/`fine` 是空间离散配置，不是 $k$ 网格。I7.1 的 final 配置预先
冻结为 main 的 `fine` 配置和 $M=48$：

```text
ntot=256, nside=160, ntop=160, nproxy=80, mpw=32, M=48 (K=97).
```

筛选配置沿用 main 的 `coarse` 参数，并取 $M=24$：

```text
ntot=160, nside=120, ntop=120, nproxy=64, mpw=24, M=24 (K=49).
```

筛选分数不能与 final 分数混合排序。最终候选只从 final 配置的有效评价中选取。

## 3. 端口未知量和中心匹配矩阵

`bloch.construct_S` 的中心 cell scattering 约定为

$$
\begin{bmatrix}b^L\\a^R\end{bmatrix}
=
\begin{bmatrix}R_L&T_{RL}\\T_{LR}&R_R\end{bmatrix}
\begin{bmatrix}a^L\\b^R\end{bmatrix}.
$$

保留 main 示例的端口入射振幅未知量

$$
q=\begin{bmatrix}a^L\\b^R\end{bmatrix}.
$$

令 $G=\operatorname{diag}(\gamma_m)$。中心胞元在左右墙上的 Dirichlet trace 为

$$
d_L=(I+R_L)a^L+T_{RL}b^R,
\qquad
d_R=T_{LR}a^L+(I+R_R)b^R.
$$

中心区域的外法向在左墙为 $-\partial_x$、右墙为 $+\partial_x$，因此对应 Neumann trace 为

$$
n_L=\mathrm{i}G\bigl[(R_L-I)a^L+T_{RL}b^R\bigr],
\qquad
n_R=\mathrm{i}G\bigl[T_{LR}a^L+(R_R-I)b^R\bigr].
$$

`LOCAL_dtn` 返回沿离开中心方向的左右 half-guide maps $\Lambda_-$ 与 $\Lambda_+$。施加
$n_L-\Lambda_-d_L=0$ 和 $n_R-\Lambda_+d_R=0$ 得到

$$
A_{\mathrm{def}}=
\begin{bmatrix}
(\mathrm{i}G-\Lambda_-)R_L-(\mathrm{i}G+\Lambda_-)&
(\mathrm{i}G-\Lambda_-)T_{RL}\\
(\mathrm{i}G-\Lambda_+)T_{LR}&
(\mathrm{i}G-\Lambda_+)R_R-(\mathrm{i}G+\Lambda_+)
\end{bmatrix}.
$$

这是本轮唯一新的中心组装公式。对空中心，$R_L=R_R=0$ 且
$T_{LR}=T_{RL}=E=\operatorname{diag}(e^{\mathrm{i}\gamma_m(X_R-X_L)})$，上式逐块精确退化为
main `betagmode.m` 的原 $A_{\mathrm{def}}$；该恒等退化是最便宜的决定性符号回归。

## 4. 权重和四个指标

保持 main 示例的 Fourier 权重。令

$$
b_m=\sqrt{1+|\beta_m|^2},
\quad
w_{r,m}=b_m^{-1/2},
\quad
w_{c,m}=\left(b_m+\frac{|\gamma_m|^2}{b_m}\right)^{-1/2}.
$$

把每个权重向量按两个端口重复，构造 $D_r,D_c$，并令

$$
A_{\mathrm{phys}}=D_rA_{\mathrm{def}}D_c.
$$

权重仍适用，因为列未知量仍是同一个 $(a^L,b^R)$ 振幅空间，两组行仍是相同 Fourier 基中的
墙上法向匹配残差；中心 scattering 只在这些坐标内混合通道。不得为中心椭圆增加整体 Frobenius
或 seed 归一化。

每个有效点一次组装矩阵后计算

$$
\sigma_{\min}(A_{\mathrm{def}}),\quad
\frac{\sigma_{\min}(A_{\mathrm{def}})}{\sigma_{\max}(A_{\mathrm{def}})},\quad
\sigma_{\min}(A_{\mathrm{phys}}),\quad
\frac{\sigma_{\min}(A_{\mathrm{phys}})}{\sigma_{\max}(A_{\mathrm{phys}})}.
$$

最终以最后一项最小的 final 有效点选择 $k$；四项必须直接来自该点的同一组矩阵。

## 5. 有界分层扫描

### 5.1 projected-gap 范围

先按 main `projgap.m` 的圆形周期 cell、coarse 空间配置、$M=12$ 和
$k=1.45:0.05:2.25$ 计算两侧周期介质的 numerical projected-gap windows。内部 gap 端点仍是
相邻 gap/non-gap 样本的中点；等于扫描端点的界限不是计算出的 band edge。后续节点必须位于
这些 numerical windows 内，并在本点 QZ 分类中满足恰有 $K$ 个 stable pairs、无 `indet`、
无 `neutral`。原空中心的窄窗口不用于椭圆发现。

### 5.2 final 优先、筛选、确认和缩区间

1. **final pilot：**gap windows 形成后，先取最宽 numerical window 的中点；若宽度并列，取
   最低 $k$ 的第一个 window。立即用 final 配置、$M=48$ 评价这一个点，并写入后续共用的
   final cache 和 history。pilot invalid 不阻止继续筛选；pilot valid 时，即使筛选层没有有效点，
   仍可按“当前扫描最佳点”交付该 final 结果。这一顺序保证低阶筛选不会耗尽 final 评价预算。
2. **筛选层：**在 numerical window 与 $0.025$ 网格的交集上，用筛选配置和 $M=24$ 计算
   `aphys_ratio`；在当前范围内最多 33 个筛选点。缓存键包含精确 $k$、空间配置 ID 和 $M$。
3. **低谷保留：**候选集合总是包含全体有效筛选点的 global minimum；再加入与其不同的最佳
   严格内点局部低谷，故总数不超过两个。边界 winner 必须明确记录边界状态。
4. **final 确认：**每个保留 seed 在裁剪到 numerical gap 内的
   $[k_{\mathrm{seed}}-0.025,k_{\mathrm{seed}}+0.025]$ 上，以 final 配置、$M=48$ 评价至多五个
   等距点。只有 final 分数可以彼此比较。
5. **final 加密：**对每个 seed，只有当当前 winner 为有效内点且两个相邻点也有效时，才用这
   两个邻点缩区间。初始五点后最多追加七次加密层；每层仍使用五点等距网格并缓存重复节点。当 bracket
   宽度不大于 $10^{-4}$、winner 位于边界、邻点无效、区间将越出 numerical gap，或为总任务
   收尾预留的资源门触发时停止。每个 seed 最多约 19 个 unique final 点，两个 seed 合计最多
   约 38 个。

若筛选 winner 位于 window 边界，final 阶段只评价范围内的单侧节点，不访问不存在的相邻索引；
不从边界向 gap 外扩张。若某层包含无效点，只在连续有效节点中判断候选，不跨无效点构造下一
bracket。最终覆盖范围、各层实际节点、未评价原因和停止条件必须保存。该过程是局部自适应扫描，
不是全局最优化。

### 5.3 无效点和低阶假低谷

以下情况把该点标为 invalid，并保存 identifier/message 或明确分类，不赋大分数：QZ `indet`、
`neutral` 或 stable count 不为 $K$；scattering、DtN 或线性求解抛错；MATLAB 报告
`singularMatrix` 或 `nearlySingularMatrix`；矩阵或奇异值非有限；$\sigma_{\max}=0$；点位于
numerical gap 外。其他 warning 也必须记录，由冻结的实现分类决定该点是否仍有效，不得静默
吞掉。一个 invalid 点不终止整个扫描。

筛选层完全没有有效点时，若 pilot 有效便正常交付 pilot；若 pilot 也 invalid，才以没有 final
有效结果停止。筛选低谷在 final 配置中消失时，保存该比较并停止继续加密该 seed；已经完成的有效 final 点仍
进入全体 final 点的比较，不得把筛选值冒充 final 结果。只要至少一个 final 点有效，就从全部已完成的 final 有效点中交付最低
`aphys_ratio`，即使它是边界点或没有明显 dip。

## 6. 函数复用与核调用修订

- `LOCAL_cellsub` 保持 main 的圆形 half-guide 构造、pencil block 顺序和返回值。
- `LOCAL_qzsub` 保持接口与主体，只在原 TODO 附近检查并记录 stable 数、`indet`、`neutral`
  与 residual；数量不合格时不提取前 $K$ 列。
- `LOCAL_dtn` 保持法向号、公式和转置线性求解；不改用 `pinv`。
- `LOCAL_point` 保持四个标量输出，调用唯一新增的 `LOCAL_center` 取得中心 scattering blocks，
  然后按第 3 节组装。
- `LOCAL_center` 只负责用椭圆 `flag_geom`、同一 `pars/chans/mfscfg` 和
  `bloch.construct_S` 构造中心 cellmap。

### 6.1 实测优先的顺序门

本轮修订不以静态内存估计直接选择适配。必须按以下顺序执行：

1. 暂时移开历史实验的 package shadow 后，先让真实 final 调用链使用公共原版
   `kernel.h2d_directch` 评价一个点，并监测 MATLAB 及子进程。若它在 30 分钟和
   3 GB（3,000,000,000 bytes）内完成，就采用公共原版并停止，不加入 batching hook。
2. 只有方案 1 记录了超时、RSS 越界、MATLAB 异常退出或明确内存分配失败，才启用第 6.2 节的
   最小适配。性能较慢但仍在硬门内不是失败。
3. 只有最小适配存在记录明确的调用链或接口障碍，才考虑 I7-local 核；不得仅因静态估计跳过
方案 1 或 2。

三种方案不改变物理模型、空间离散、$k$ 节点、矩阵组装、候选选择或 `out` 语义。每个实测使用
独立运行目录并保留命令、公共 `which` 路径、退出状态、wall time 与 process-tree peak RSS。

方案 1 已按此顺序实测。MATLAB 明确解析到仓库公共
`+kernel/h2d_directch.m`，完成 17 个 gap 点后进入首个 final pilot；监测器在第 42 s 采样到
process-tree peak RSS 3,105,751,040 bytes，超过 3,000,000,000-byte 硬门，随后终止进程。包括
终止等待在内的 wall time 为 47 s，exit code 为 143。证据目录为
`test/i7/scan-v1/output/attempt-1/kernel-revision/scheme-1-run-01/`。因此方案 1 被资源门否决，方案 2
获得条件授权；方案 2 的资源失败或明确接入障碍均尚未发生，方案 3 未采用。

### 6.2 现行方案：公共核的 target batching hook

若且仅若方案 1 实测失败，最小接入点是公共
`kernel.qpgreen_mfs_pairmat` 内 proxy sources 对全部 pair targets 的一次调用。该例程可读取可选
`pars1.h2d_evaluator`；字段缺失或为空时必须执行原调用
`kernel.h2d_directch(k,Z,q,T_in)`，因此所有既有 caller 的缺省行为不变。I7 的
`LOCAL_cellsub` 与 `LOCAL_center` 只给各自 `pars` 设置同一个 `@LOCAL_h2d_chunked_public`。

`LOCAL_h2d_chunked_public` 保持公共核的四输入、三输出接口

```text
[pot,grad,hess] = evaluator(k,sources,charge,targ)
```

它预分配 $1\times n_t$、$2\times n_t$、$3\times n_t$ 输出，仅切分 `targ` 的列；每批实际调用
公共 `kernel.h2d_directch`，再按原 target 顺序拼接。它不复制 Hankel 公式、不改变 source 求和、
不作新的归一化，也不形成同名 package shadow。primary-source 调用和 regular-diagonal 的单 target
调用仍直接使用公共核；`bloch.construct_S` 与 `op.construct_A_QP` 无需改动。

启用前的最小验证为：缺省字段走原路径；至少一个多批小例的 potential、gradient、Hessian 与
公共整批结果在浮点误差内一致；helper 内部 `which('kernel.h2d_directch')` 指向公共文件；真实 final
调用符合时间和 RSS 门。任一项失败都必须保存证据，不能转而静默使用历史 shadow。

`scheme-2-run-01` 已通过这些门。direct public/batched 的三项相对差异均为 0；pair-matrix 的缺省、
显式公共 evaluator 与 batched evaluator 六项相对差异也均为 0。MATLAB 解析到仓库公共
`+kernel/h2d_directch.m`，历史 `tmp/` 不在 path。完整扫描 exit code 为 0，wall time 203 s，
process-tree peak RSS 1,071,398,912 bytes，低于 3,000,000,000-byte 门；因此方案 2 是现行实现，
未触发方案 3。修正后的 `audit-run-02` 进一步确认旧/新 `out` 的前六个标量差为 0，history 的科学字段（不含逐点评价耗时）、科学
配置、扫描覆盖、final argmin、核回归和路径检查完全一致；audit exit code 为 0，wall time 17 s，
peak process-tree RSS 851,787,776 bytes。此前一次 audit 命令的括号语法错误以 exit code 1 保留在
`audit/`，没有修改正式 run 或其产物。

### 6.3 历史实现边界

`attempt-1/run-01` 曾使用 `test/i7/scan-v1/+kernel/` 的 formula-copy target-block 实现，并完成三输出
零差异回归。该结果仍是 I7.1 数值结果的历史证据，但该核文件不是本轮现行路径；其原命令、数据
和解释不因本轮修订而重写。

## 7. 输出、运行记录和资源门

入口调用形式为 `out = scan_i7(output_dir)`；`output_dir` 是由受监测 launcher 显式创建的本次
运行目录，数值入口不发现仓库根目录，也不读取 Markdown、Git 或历史结果。入口只返回

```text
out.beta, out.k, out.adef_sigma, out.adef_ratio,
out.aphys_sigma, out.aphys_ratio, out.runtime
```

七个字段全部是标量；四个矩阵指标来自选定 final 点。`runtime` 是整个入口耗时。
扫描历史、配置、invalid 原因、诊断、停止原因和资源样本另存，不扩张 `out`。

实验目录为 `test/i7/scan-v1/`。同一科学方案的程序错误在 `output/attempt-1/` 内修复，每次运行
使用 `run-NN/` 保存日志，不覆盖失败证据。只有几何或扫描方法发生科学变化时才新建 attempt，
并先说明原因。

本轮核调用修订的单次计算硬门为 30 分钟和 3 GB（3,000,000,000 bytes）；监测 MATLAB 及其
子进程，不得并发叠加计算，也不得延长硬门。首先只运行第 6.1 节的一个 final 点；只有该实测失败
才进入条件备用。总任务从 2026-09-22 14:47:14 UTC 起计，最晚 16:17:14 UTC 结束，并预留收尾
时间。方案 2 验证通过后的扫描仍按第 5 节的冻结预算退出规则运行；不得降低 final 空间配置，
也不得以筛选结果替代 final 结果。

## 8. 回归、解释和停止

最低静态/数值回归为：

1. 空中心 scattering blocks 代入新公式应与旧 $A_{\mathrm{def}}$ 达到普通浮点舍入误差；
2. half-guide geometry 仍为 circle radius $0.2$，中心 geometry 为 ellipse $0.25/0.16$；
3. 必要时只用圆形中心或空中心作实现回归，不把它们加入椭圆候选排序；
4. final winner 重算一次，核对保存的四指标与同一矩阵；
5. 检查 `out` 字段和标量性，核对没有 `pinv`、额外整体归一化或第 6.2 节以外的公共文件修改。

正常停止包括：达到 spacing/层数、边界 winner、invalid 邻点阻止 bracket、资源预留门或所有
预先冻结 basin 已确认。只有 final 配置始终没有有效评价时才不交付 `out`；此时必须保存真实
失败原因，不能用 `NaN`、预测值或筛选层结果补足。

## 9. 历史 Attempt-1 执行注记

`run-01` 按本设计完成 17 个 gap、33 个 screening、6 个 unique final 和 1 个 final repeat
调用，共 57 次；没有 invalid 评价。筛选 global minimum 和 final 确认 minimum 都位于扫描
下边界 $k=1.45$，所以实际在初始五点 final 网格后按边界停止，未消费“最多追加七次”的可选
加密层。这是第 5 节预注册的正常停止条件，不是扫描方案变化，也没有产生新 attempt。

该 `run-01` 先于第 6 节的核调用修订，使用现已移出 active package path 的 formula-copy kernel。
其扫描结论和保存数据不变，但不能作为公共原版在新 3 GB 门内可运行的实测证据。

## 10. 核调用修订执行注记

`scheme-1-run-01` 按第 6.1 节被 3 GB 资源门否决；`scheme-2-run-01` 随后按同一模型和扫描方案完成。
现行 run 仍得到 $k=1.45$ 的左边界当前最佳点，四个指标为
$3.6371178757473972$、$0.0060199359811023666$、$1.3746238403333091$、
$0.31371305311538561$，入口 runtime 为 $182.508327708$ s。它完成 17 个 gap、33 个 screening、
6 个 unique final 和 1 个 final repeat 评价且没有 invalid 点；边界停止条件未变。该数值一致性支持
“内存调度改变而数学扫描不变”的实现主张，但不把边界最小升级为内点 dip 或特征值。
本轮方案 1、正式方案 2、失败 audit 与修正 audit 的受监测 MATLAB wall time 合计 288 s；最高
process-tree RSS 是方案 1 的 3,105,751,040 bytes，成功正式 run 的峰值为 1,071,398,912 bytes。
