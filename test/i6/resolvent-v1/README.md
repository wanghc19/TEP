# I6.1a：raw 界面缺陷的预解式谱距离实验

2026-09-18，在 `codex/epost` 完成首轮端到端计算。有效产物为
`output/attempt-1/run-04/`；run-03 是同数值的有效结果，run-04 修正了尾项诊断标志。
此前两个程序失败 run 保留，未用于最终结论。
本轮实际采用 Researcher–Engineer–Skeptic 协作；设计及局部推导见
[design-6-1a.md](design-6-1a.md)，独立审查和修复记录见
[review-6-1a.md](review-6-1a.md)。

## 实际结果

同一冻结 candidate 为 $\widehat k=1.832770289108157$、
$\mu=\widehat k^2=3.3590469326375971$，固定 $\beta=0.5$。按当前理论 F14 得到

$$
R_{\mathrm{spec}}=7.387058992105812\times10^{-4},
\qquad
[\mu-R_{\mathrm{spec}},\mu+R_{\mathrm{spec}}]
=[3.3583082267383864,\ 3.3597856385368079].
$$

**这是理论上界公式的普通浮点评价，即非认证的谱距离上界估计。** 连续高模尾与
无限胞元尾已计入；特殊函数、一般舍入及质量单侧下取的完整包围尚未建立，
因此不称严格谱包含。该区间使用频率平方参数 $\mu$，不是 $\widehat k$ 区间。
本轮没有独立认证本质谱带隙，不声称离散特征值存在或唯一，也不识别特征值编号。

| 核心量 | run-04 普通浮点评价值 |
|---|---:|
| $\overline C$ | 2.3499520103811307 |
| $\overline\varepsilon_\partial$ | $5.8366835878255165\times10^{-5}$ |
| $\underline U$（中心解析质量范数的非认证评价） | 1.2475196512735218 |
| $\overline Q=\overline C\,\overline\varepsilon_\partial$ | $1.3715926331169122\times10^{-4}$ |
| $\overline Q/\underline U$ | $1.0994557333960482\times10^{-4}$ |
| $\underline U-\overline Q$ | 1.2473824920102101 |
| $\overline\varepsilon_{\mathrm{vol}}$ | 0，精确连续 raw 模型的结构性零 |
| 上下准周期缺陷 | 0，同一模型的 Bloch 拼接结构性零 |
| $R_{\mathrm{spec}}$ | $7.387058992105812\times10^{-4}$ |

分母明确为正，约为质量的 $0.9998900544$ 倍，未取绝对值，也未替换成旧 lift
路线的移位能量。辅助预解式场 $z$ 只用于理论证明，计算中没有求解它。

### 完整界面与尾项分解

下表均为 **$L^2$ 范数控制量的平方**。本实例取 $\ell_*=d=1$，值项仍按
$\ell_*^{-2}$ 进入总缺陷。材料法向是普通法向导数，不是加权通量，也不是旧负阶范数。

| 类型 | singleton | 有限部分 | 无限胞元尾 | 全序列高模尾 | 合计 |
|---|---:|---:|---:|---:|---:|
| 材料值跳跃 | 0 | $5.2535965137\times10^{-19}$ | $1.6829326089\times10^{-32}$ | $1.9928163273\times10^{-14}$ | $1.9928688633\times10^{-14}$ |
| 材料法向跳跃 | 0 | $1.1980008153\times10^{-16}$ | $3.8376763984\times10^{-30}$ | $3.4066674819\times10^{-9}$ | $3.4066676017\times10^{-9}$ |
| 人工墙值跳跃 | $1.1567019305\times10^{-31}$ | $3.6152307326\times10^{-31}$ | $2.4137656212\times10^{-48}$ | $1.0766081547\times10^{-306}$ | $4.7719326631\times10^{-31}$ |
| 人工墙法向跳跃 | $9.8960162857\times10^{-20}$ | $1.0582304220\times10^{-26}$ | $6.8916667554\times10^{-44}$ | $2.8031383667\times10^{-300}$ | $9.8960173439\times10^{-20}$ |

因此值跳跃总平方为 $1.9928688633084422\times10^{-14}$，法向跳跃总平方为
$3.4066676017505415\times10^{-9}$，总缺陷平方为
$3.4066875304391745\times10^{-9}$。singleton 是两条中心/首胞人工墙；中心为空列，
没有中心材料圆。左右材料序列从实际首胞开始，人工内部墙先形成两侧配对行再取范数。
高模尾覆盖全部胞元；胞元尾仅补足保留模态的 $n\ge16$ 部分，二者没有遗漏或重复。

材料法向高模解析界占总缺陷平方约 $99.9994115\%$，是目前保守性的主要来源。
细分后主导者是 local 四阶导数尾系数
$3.5897742677909776\times10^{-13}$ 乘全 lead state-energy 上界
9489.9211697448736；regular/off-surface 的解析 strip 尾远小于此项。
这一过程使用 operator 包络、不同来源的三角合并，以及全矩阵状态能量界。
有限行、人工墙和截去的远胞元贡献远小于此项。当前已得到有效的有限公式评价，
因此没有为了缩小结果另开 attempt 或改变冻结场。

## 科学配置和理论适用性

| 输入 | 值或方法 |
|---|---|
| 周期 $L,d$ | 1, 1 |
| inclusion | 单个半径 0.2 的圆；周期复制，中心缺陷列为空 |
| 材料 $\rho_e,\rho_{\mathrm{disk}}$ | 1, 17 |
| 中心区间 $[X_L,X_R]$ | $[-0.5,0.5]$ |
| collar 半宽 $h$，曲率上界 | 0.04，5 |
| Jacobian 下界 $\theta$，覆盖重数 | 0.8，1 |
| 频率窗口 | 点窗口 $[\mu,\mu]$ |
| 参考长度 $\ell_*$ | 1 |
| 每侧状态维数 | 97 |
| 有限胞元数 $J$ | 每侧 16 |
| 材料保留模态 | $|m|<1024$；行包目标节点数 16384 |
| 人工墙保留模态 | $|m|\le256$；高模从 257 开始 |
| 完整 $P_\pm$ 尾控制块长 | 32 |
| raw 质量 | 空中心 Rayleigh Gram 解析积分，无需全波导体积分 |

$c_0=N_{\mathrm{ov}}/(\theta h)=31.25$、
$c_1=N_{\mathrm{ov}}h/(2\theta)=0.025$，使用 T9--T10 的

$$
\overline C^2=\frac{c_0}{\rho_{\min}\mu^2}
+\frac{c_1+\ell_*^2c_0}{4\mu}
+\ell_*^2c_1\rho_{\max}=5.5222744510943178.
$$

圆与竖墙 collar 的单射和不相交来自上述实际有限几何参数。完整传播矩阵的
$\|P_-^{32}\|_F=6.5904121972554585\times10^{-18}$、
$\|P_+^{32}\|_F=6.5904121972619458\times10^{-18}$，均小于 1。
相应 $\sum_{r=0}^{31}\|P_\pm^r\|_F^2/(1-\|P_\pm^{32}\|_F^2)$ 均为
97.092626297679615；所有矩阵都完整保留，没有独立标量模态替代。

体内与上下准周期缺陷为零的依据是原始有限密度配合精确连续层势/Rayleigh 表示，
见设计文件的来源核对。普通浮点迹评价的误差没有因此被宣称为零。

## 复现入口与产物

MATLAB 数值入口为 [resolvent_bound_v1.m](resolvent_bound_v1.m)，唯一局部 MATLAB
辅助文件为 [signed_wall_l2_v1.m](signed_wall_l2_v1.m)。必要输入为
`input/frozen-candidate.mat` 和 `input/i5-v7-attempt6-signed-rows.mat`。
运行时不解析 Markdown、Git、哈希、旧最终 estimator 或旧最终报告；行包只是显式
科学输入。将两个 MATLAB 文件及必要 MAT 输入一起移动并放入 MATLAB path 后即可执行。

下面命令在本实验目录执行，选择一个尚不存在的新 run 路径；当前有效产物不能覆盖：

```sh
python3 run_with_limits.py /Applications/MATLAB_R2023b.app/bin/matlab \
  "$PWD" "$PWD/input/frozen-candidate.mat" \
  "$PWD/input/i5-v7-attempt6-signed-rows.mat" \
  "$PWD/output/attempt-1/run-05"
```

这是未来复现命令，本轮没有启动 run-05。Python launcher 只负责源码快照、调用 MATLAB
及资源监控；所需模块均来自 Python 标准库，RSS 监控使用 POSIX `ps`。
等价的 MATLAB `-batch` 表达式见有效 run 的
`run-config.json`，核心调用是：

```matlab
addpath(source_directory);
resolvent_bound_v1(candidate_path, signed_rows_path, ...
  input_snapshot_path, result_mat_path, summary_json_path);
```

五个路径是明确输入；三个输出路径的父目录须存在，文件本身须不存在。科学配置在入口
源代码内明确定义，并写入输入快照。本轮使用 MATLAB R2023b，未使用 Octave。

有效 run 的主要证据：

- [summary.json](output/attempt-1/run-04/summary.json)：轻量机器可读结果和分解。
- [result.mat](output/attempt-1/run-04/result.mat)：详细高模子项、质量逐模贡献及检查。
- [input-snapshot.mat](output/attempt-1/run-04/input-snapshot.mat)：实际科学输入、配置和 checkpoint。
- [run.log](output/attempt-1/run-04/run.log)、[run-config.json](output/attempt-1/run-04/run-config.json)：MATLAB 阶段日志和实际调用。
- [resource.json](output/attempt-1/run-04/resource.json)、[resource-samples.jsonl](output/attempt-1/run-04/resource-samples.jsonl)：资源结果和运行中采样。
- `output/attempt-1/run-04/source/`：实际执行的 MATLAB 源码和 watchdog 快照。
- [input-provenance.json](input/input-provenance.json)：显式输入的复制来源，仅作出处记录。
- [run-ledger.json](output/attempt-1/run-ledger.json)：全部 run 状态和资源记录。
- [SYMBOLS.md](SYMBOLS.md)：数学到变量映射；代码内的 legacy `z` 是输入结构，不是证明中的预解式场。

## 运行历史、检查与限制

| Run | 目的与结果 | 完整墙钟秒数 | 采样进程树峰值 bytes |
|---|---|---:|---:|
| attempt-1/run-01 | 首次运行；误选旧未通过输入包，输入检查失败 | 22.518 | 945,897,472 |
| attempt-1/run-02 | 更正输入及 schema；结果组装字段拼写错误 | 26.302 | 1,444,642,816 |
| attempt-1/run-03 | 仅修正输出适配并加日志/checkpoint；成功，返回码 0 | 23.155 | 1,387,380,736 |
| attempt-1/run-04 | 仅修复尾项 floor 诊断；成功，核心数值与 run-03 完全一致 | 24.490 | 1,343,242,240 |

每次运行都受 2700 秒、3,000,000,000 bytes 限制，无宽限；达到阈值立即杀死本任务
进程组。RSS 为约 0.25 秒间隔的进程树采样峰值，不是操作系统连续峰值证明。
全部已测峰值和耗时均低于硬限。另有运行前 MATLAB 只读字段/schema 检查，不是另一轮
科学实验，其时间也计入总任务时限。错误修复没有重置总时限。

任务起点为 **2026-09-18 13:14:06 UTC**；最终验收记录时刻为
**13:51:08 UTC**，总墙钟 **37 分 02 秒（约 37 分钟）**，包含阅读、协作、编程、
调试、运行、等待和文档审查。四次完整 MATLAB launcher 耗时之和为 96.465 秒，
它不是总任务耗时。原截止 16:14:06 UTC 未重置，提前完成交付。

实际检查包括：冻结对象绑定、材料/墙界面计数与方向、完整 $P$ 尾、模态分区、有限非负
结果、同场质量与分母，以及从 JSON 独立重算缺陷、$Q$、分母、F14 和区间。
标量重算与 MATLAB 输出一致。中心解析质量与 4001 点梯形积分诊断的相对差为
$2.3152837984732357\times10^{-8}$；梯形值只作诊断，没有充当质量下界。

墙尾中 $r^{257}$ 小于正常浮点数范围，使用正的 `realmin` 替代以避免把遗漏尾写成零，
随后所有正因子及状态能量照常计入。run-04 明确记录
`primitiveFloor=1, aggregateFloor=0`；两步状态含义不同。该保守防下溢处理不等于
一般舍入已经向外包围。Skeptic 独立核对 run-04 与 run-03 的全部科学数值一致，
最终结论为“非认证公式评价通过，完整认证条件尚未关闭”，无本层级的数学或数值 blocker。

未完成的工作是特殊函数和舍入的单侧包围、质量下取以及独立带隙认证；前两者影响
严格数值可靠性，后者影响能否解释为离散特征值存在性。它们不妨碍交付本轮明确标注的
非认证公式评价。本轮未创建 `implementation/i6`，未更改既有理论、i5、公共 package、
main draft、参考文献或上级维护文档，未提交 Git。
