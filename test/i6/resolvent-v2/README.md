# I6：直接计算界面跳跃范数

> 路径迁移（2026-09-20）：本目录原名 `test/i6/resolvent-nonfourier-v1/`，
> 现为 `test/i6/resolvent-v2/`。设计、审查与符号映射已迁至
> `research/projects/eig-apost/implementation/i6/`。历史日志、原始 JSON/MAT 和源码快照
> 逐字节保留，因此其中的旧绝对路径是历史记录；以下当前复现命令使用新路径。
> 本版本保留非认证结果；认证版本另见 `test/i6/resolvent-v3/`。

本轮完成同一冻结 raw 场的 MATLAB 计算。有效结果为 attempt-1/run-02：

$$
\widehat k=1.832770289108157,\qquad
\mu=3.3590469326375971,\qquad
R_{\mathrm{spec}}=4.0547573451465766\times10^{-9}.
$$

对应的谱参数区间是
$[3.3590469285828397,\;3.3590469366923545]$，单位和变量均为 $\mu=\widehat k^2$。
这是 **resolvent 理论谱距离上界公式的普通浮点评价，未认证**，不是 residual 范数。
它达到本轮 $10^{-6}$ 目标，但尚不能据此声称严格谱包含、离散特征值存在、唯一或编号。

材料界面不建立跳跃的 Fourier 系数或高模尾：在物理曲线节点先合并有符号行，再取
平方求积，另加连续源核尾、regular-image 余项及解析目标求积余项。原始有限 density
和人工墙仍保留已有 Fourier/Rayleigh 表示；完整 $P_\pm$ 始终保留，没有重新搜索
candidate、求解辅助预解式场或构造 lift。

## 阅读顺序与文件

- [design-6-1b.md](../../../research/projects/eig-apost/implementation/i6/design-6-1b.md)：模型边界、旧 I5 失败原因、三个局部引理及 (NF1)--(NF6)。
- [review-6-1b.md](../../../research/projects/eig-apost/implementation/i6/review-6-1b.md)：Researcher–Engineer–Skeptic 实际协作、独立审查、修复与最终结论。
- [SYMBOLS.md](../../../research/projects/eig-apost/implementation/i6/SYMBOLS.md)：理论到 MATLAB 的变量、单位和所有权映射。
- [resolvent_nonfourier_v1.m](resolvent_nonfourier_v1.m)：MATLAB 入口；四个 `signed_*` 文件为局部计算依赖。
- [summary.json](output/attempt-1/run-02/summary.json)：完整轻量分项与可靠性字段。
- [result.mat](output/attempt-1/run-02/result.mat)：结果及逐胞元/质量明细。
- [input-snapshot.mat](output/attempt-1/run-02/input-snapshot.mat)：本次实际科学输入、配置与检查点。
- [run-config.json](output/attempt-1/run-02/run-config.json)、[resource.json](output/attempt-1/run-02/resource.json)、[run.log](output/attempt-1/run-02/run.log)：实际命令、资源和日志；源码快照在同目录 `source/`。

## 物理输入、常数与核心结果

$\beta=0.5$，$d=L=1$，圆 inclusion 半径 $R=0.2$，外部材料 $\rho_e=1$，
inclusion 材料 $\rho_{\mathrm{disk}}=17$。inclusion 是单个单连通区域；本轮利用圆的
特殊结构，不声称任意单连通曲线均满足相同的有限源求积精确性。
空中心列为 $[-0.5,0.5]\times(-0.5,0.5)$，无中心材料 singleton；两条中心/首胞墙均计入。

collar 半宽 $h=0.04$、曲率界 $\kappa_*=5$、$\theta=1-h\kappa_*=0.8$、覆盖重数 1，
参考长度 $\ell_*=1$。材料/墙、相邻周期副本的 collar 分离门均通过。
T9 取点窗口 $I=[\mu,\mu]$，$c_0=31.25$、$c_1=0.025$，故

$$
\overline C^2=
\frac{c_0}{\rho_-\mu^2}+
\frac{c_1+\ell_*^2c_0}{4\mu}+\ell_*^2c_1\rho_+
=5.5222744510943178.
$$

| 量 | run-02 数值 |
|---|---:|
| $\overline C$ | 2.3499520103811307 |
| $\overline\varepsilon_\partial^2$ | $1.0266310779308423\times10^{-19}$ |
| $\overline\varepsilon_\partial$ | $3.2041084219027955\times10^{-10}$ |
| $\underline U$ 的浮点评价 | 1.2475196512735218 |
| $\overline Q=\overline C\overline\varepsilon_\partial$ | $7.5295010275295862\times10^{-10}$ |
| $\overline Q/\underline U$ | $6.035577090784219\times10^{-10}$ |
| 分母 $\underline U-\overline Q$ | 1.2475196505205717 |
| $\overline\varepsilon_{\mathrm{vol}}$ | 0，限于下述 exact-kernel 数学 raw 场 |
| 准周期 seam 缺陷 | 0，限于下述 exact-kernel 数学 raw 场 |
| $R_{\mathrm{spec}}=(2\mu\overline Q+\overline\varepsilon_{\mathrm{vol}})/(\underline U-\overline Q)$ | $4.0547573451465766\times10^{-9}$ |

质量使用同一冻结 $q_{\mathrm{center}}$ 的空中心有限区域解析 Rayleigh Gram 积分。
精确算术下，区域质量不大于全条带质量；当前数值未向下包围，故字段虽然名为
`U_lower`，其认证标志明确为 false。另作体积求积的一致性诊断相对差为
$2.3152837984732357\times10^{-8}$，不是质量误差上界或收敛认证。

raw 场由有限密度作用于完整精确准周期核，加完整冻结 Rayleigh 和定义。因此每片
Helmholtz 方程及准周期条件在数学对象层面精确成立；数值核截断用于评价跳跃，
其误差已进入节点半径。不能把截断的评价程序重新定义成 raw 场后仍宣称 PDE 精确。
特殊函数与一般浮点误差未包围，与上述解析 PDE/准周期缺陷为零是不同问题。

## 全界面分项

下表均为相应 $L^2$ 控制量的**平方**；本实例 $\ell_*=1$，值项权重数值为 1。

| 类型 | singleton | 有限胞元 | 无限胞元尾 | 模态尾 | 合计 |
|---|---:|---:|---:|---:|---:|
| 材料值跳跃 | 0 | $5.104742972679781\times10^{-24}$ | $1.583635098206074\times10^{-37}$ | 不适用 | $5.10474297267994\times10^{-24}$ |
| 材料普通法向跳跃 | 0 | $3.698095112506441\times10^{-21}$ | $1.1777381281389382\times10^{-34}$ | 不适用 | $3.6980951125065595\times10^{-21}$ |
| 人工墙值跳跃 | $2.328732147200838\times10^{-31}$ | $4.9445707122044825\times10^{-31}$ | $3.3143269286800074\times10^{-48}$ | $1.0766081547103482\times10^{-306}$ | $7.273302859405321\times10^{-31}$ |
| 人工墙普通法向跳跃 | $9.895989735210622\times10^{-20}$ | $1.0584771442425489\times10^{-26}$ | $6.893426440522951\times10^{-44}$ | $2.803138366730395\times10^{-300}$ | $9.895990793687766\times10^{-20}$ |

材料有限部分为两侧各 $n=0,\ldots,15$，无材料 singleton；墙 singleton 指两条中心/首胞墙。
所有无限胞元平方尾之和为 $1.17932176392652\times10^{-34}$。
使用完整矩阵的块长 32，$\|P_-^{32}\|$、$\|P_+^{32}\|$ 的计算上界分别为
$6.5904121972554585\times10^{-18}$、$6.590412197261946\times10^{-18}$，
两侧幂和系数均为 97.09262629767962。未将矩阵对角化为独立标量模态。

材料 `high_mode_squared=0` 仅为兼容字段，同时有 `material_high_mode_applicable=false`：
完整曲线积分加解析余项已经覆盖全部目标变化，没有把未知高模尾设零。
墙的极小正尾保留正数 floor，详见 JSON 和源码。

## 跳跃中心、评价误差与认证误差分开

| 材料有限部分平方 | 值跳跃 | 普通法向跳跃 |
|---|---:|---:|
| 实际有符号节点中心的平方求积（诊断） | $1.857636236536247\times10^{-27}$ | $6.717251576617749\times10^{-26}$ |
| 节点半径引起的平方增量，含交互项 | $5.102885336443245\times10^{-24}$ | $3.698027939990675\times10^{-21}$ |
| 解析目标求积余项 | $3.1199373583621956\times10^{-84}$ | $1.8940496648346156\times10^{-82}$ |

节点行半径为 $1.4334139648903108\times10^{-12}$（值）和
$3.917038712579\times10^{-11}$（普通法向）。其所有者为：

| 节点半径来源 | 值 | 普通法向 |
|---|---:|---:|
| local 连续核级数尾 | $5.110826326227796\times10^{-60}$ | $3.83985300967305\times10^{-59}$ |
| regular 源求积余项 | $2.494508520549908\times10^{-87}$ | $1.9368413828465225\times10^{-86}$ |
| regular $M_R$ | $2.0181615790684077\times10^{-26}$ | $7.396130843336047\times10^{-25}$ |
| regular $M_I$ | $9.803461072199312\times10^{-13}$ | $3.114614960631231\times10^{-11}$ |
| regular $M_T$ | $1.2066991887382019\times10^{-30}$ | $1.8313494368392182\times10^{-29}$ |
| regular $M_L$ | $4.5306785767035926\times10^{-13}$ | $8.024237519476953\times10^{-12}$ |

retained local 源因子乘冻结密度的最大次数 161，小于 Nyquist 513，源求积在精确算术
下精确；遗漏的连续核尾仍如上计入。完整行 strip 包络为 292.15171014352023 和
2276.308798130051；目标余项系数为 $1.9187225211100414\times10^{-89}$，由解析
轮廓公式得到，不以采样最大值或加密差代替上界。旧 source 四阶包络只作为 inactive
诊断保留；不是仍应再加入的一份误差。

**尚未评价为单侧上界的误差**包括特殊函数、系数组装和强相消的一般浮点舍入、
传播/trace 上界的向外舍入，以及质量的向下舍入。因此全部上述上界公式虽有连续
数学依据，本次数值只能标为 `NON_CERTIFIED_FORMULA_EVALUATION`。极小的 signed
中心只能作为诊断，不能单独宣称真实跳跃已精确到该量级。

## 与基线的对比及瓶颈

| 指标 | I6 resolvent-v1 / attempt-1/run-04 | 本轮 attempt-1/run-02 |
|---|---:|---:|
| $R_{\mathrm{spec}}$ | $7.387058992105812\times10^{-4}$ | $4.0547573451465766\times10^{-9}$ |
| 材料普通法向合计平方 | $3.4066676016515813\times10^{-9}$ | $3.6980951125065595\times10^{-21}$ |
| 人工墙普通法向合计平方 | $9.896017343932306\times10^{-20}$ | $9.895990793687766\times10^{-20}$ |
| $\overline C$ | 2.3499520103811307 | 相同 |
| 质量评价 | 1.2475196512735218 | 相同 |

谱距估计缩小约 **182182.5 倍**。原基线的材料法向高模平方
$3.4066674818514996\times10^{-9}$ 是主要损失；新方法以完整有符号行、有限状态和
展开的连续余项替代该项，没有把它直接删除后保留截断范数。
I5 v8 的零导数中心与巨大导数包络也没有移植过来。

墙沿用基线公式并重评。本轮共享求积几何为 $N=1026,a=0.2$，原基线为
$N=16384,a=0.3$，故墙的源求积中心及显式半径也有极小变化；这从 attempt-1 起即是
声明的评价配置，不改变 raw 场。墙法向平方绝对变化仅
$-2.655024454007252\times10^{-25}$，不是改善的主要来源。

本轮人工墙法向项占总缺陷平方约 **96.3929%**；材料法向项占约 **3.6022%**，且主要
由 regular $M_I,M_L$ 半径控制。未来若继续收紧，应先查两条中心墙的法向项及其
浮点评价，再收紧 Ewald 半径；目前增加材料节点数对结果几乎无帮助。本轮目标已完成，
没有为取得更小数字重复搜索 candidate 或启动第二 attempt。

## 重现与资源

实际使用 MATLAB R2023b 非交互运行。可在本机以新 run 目录重现：

```sh
conda activate octave
task_root=/Users/whc/Documents/Work/epost/test/i6/resolvent-v2
python "$task_root/run_with_limits.py" \
  /Applications/MATLAB_R2023b.app/bin/matlab \
  "$task_root" /Users/whc/Documents/Work/epost \
  "$task_root/input/frozen-candidate.mat" \
  "$task_root/input/circle-contract-a1.mat" \
  "$task_root/output/attempt-1/run-03"
```

此命令通过 watchdog 调用 MATLAB 入口
`resolvent_nonfourier_v1(candidate_path, curve_path, snapshot_path, output_path, json_path)`。
入口接受显式科学输入，不解析 README、Markdown、Git、哈希或旧结果。
依赖通过 MATLAB 正常路径解析；外部项目函数仅为 `+geom/construct_cont.m` 与
`+quad/quad_kress_rvec.m`。所需本地 `signed_*` 与这两个包函数可随实验移动，
无需数值源码硬编码旧目录。实际 run-02 的完整 `-batch` 命令保存在 run-config.json。
不要覆盖 run-01/run-02；上例 run-03 尚未执行。

attempt-1 固定：$N=1026$、$a=0.2$、核截断 $Q=32$、每侧有限胞元 $J=16$、
完整传播块长 32、墙模态截断 256，Ewald split/reciprocal/image/local/Taylor 参数
分别为 2/5/3/18/18，target block 4。源码快照是每次实际运行的版本。

| run | 目的与结果 | 墙钟秒 | 采样进程树峰值 RSS |
|---|---|---:|---:|
| run-01 | 首次启动；MATLAB_PREFDIR 相对路径无效，进入科学阶段前失败；证据保留 | 1.083770583 | 159956992 bytes |
| run-02 | 全部入口路径转绝对路径后的同方案重跑；完成，return code 0 | 34.583710125 | 1034289152 bytes |

run-02 MATLAB 内计算到保存前计时 11.882893875 秒；整 run 的 34.58 秒含启动及退出。
预估为 1--3 分钟、低于 2 GB；实际未触及 2700 秒或 3000000000 bytes 限制。
watchdog 约每 0.25 秒采样进程树，记录的是可获得的**采样峰值**，不是连续时间 OS 峰值；
触限策略为立即终止本任务进程组，无宽限。原始采样保存在各 run 中。

本轮任务起点 2026-09-20 01:29:35 UTC，截止 04:29:35 UTC；最终审查与交付时间见
implementation/i6/review-6-1b.md 的收尾记录。分支为 codex/epost；全部新增文件限定在本专题目录，没有 commit 或 push。
