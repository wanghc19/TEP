# I8.4 第二阶段：FMM 谱距离数值估计独立审查

日期：2026-10-21。审查对象为 `I8.4B-FMM-FROZEN-FIELD-V1`、
`test/i8/fmm-est-v1/output/attempt-1/run-03/`。
**结论：PASS WITH CONDITIONS，无未解决 blocker；状态为 UNCERTIFIED_RNUM。**

本记录由主代理整理 Skeptic 的只读审查报告。Skeptic 实际读取新源码、运行快照、
原始 `scientific.mat`、标量结果和资源日志，并亲自运行已保存的
`test/i8/fmm-est-v1/skeptic_audit.py`；没有启动 MATLAB 或安装依赖。
Researcher、Engineer、Skeptic 为本轮新建代理，创建工具均接受显式
`gpt-6-astra / high` 参数，未复用旧模型代理。工具未提供运行时模型遥测，
因此只能确认请求及工具接受结果，不能独立证明实际路由。

权威与范围：[[research/projects/eig-apost/implementation/i8/design-8-4a|两阶段设计第10节]]、
[[research/projects/eig-apost/implementation/i8/review-8-3a|I8.3审查]]、
[[test/i8/estimate-v1/README|既有完整跳跃实现]]及
[[test/i8/fmm-est-v1/README|本轮复现说明]]。第一阶段审查保持不变。
本轮仅接受新候选上的未认证数值估计，不审查扫描无遗漏、连续特征值存在性或可靠谱距离上界。

## 1. 新场与对照对象

实际 literal 为 $k_0=1.7562818500073423$，center512／lead256，主评价768、
native诊断512，FMM请求容差 `1e-12`。中心六行星形缩放、lead模型、其余离散、
密度缩放、QZ/DtN、匹配权重和归一化均遵循冻结条件。

FMM只替换 smooth proxy 势、梯度和Hessian；材料奇异核、Kress、跳跃、自由空间和外侧
Rayleigh分支未被普通FMM点源求和替代。direct768路径在同一实现中只切换评价器，
重新评价完整材料、墙、40-cell前缀、尾项和fine质量，没有重新求场。
原始两路 center 的 density、scale、Bq、weights，以及 lead 的 density map、scale、B、
weights均逐位相同。归一化 $\|q\|_2=1$，密度从保存的 $H_L,H_R,q$ 重建相对差
$1.82\times10^{-16}$，两层FFT插值重组相对差不超过 $2.45\times10^{-16}$。

## 2. 主标量与数值意义

| 量 | FMM主层768 | 同场direct768 |
|---|---:|---:|
| $\mu_{\rm num}=\operatorname{fl}(k_0k_0)$ | 3.0845259366652127 | 相同 |
| $C_{\rm num}$ | 8.2735456668590359 | 相同 |
| $\varepsilon_{\rm num}$ | 1.6064304963971742e-12 | 1.6057993786883599e-12 |
| $U_{\rm num}$ | 0.11608305827964503 | 相同 |
| $Q_{\rm num}$ | 1.329087607257705e-11 | 1.3285654491392012e-11 |
| $U_{\rm num}-Q_{\rm num}$ | 0.11608305826635415 | 0.11608305826635938 |
| $R_{\rm num}$ | **7.0632274130478178e-10** | **7.06045248570906e-10** |

独立重算 $C$，从原始 signed samples、逐胞元行和质量样本重组 $E_v,E_n,U$，
再按 $\varepsilon=\sqrt{E_n+E_v/d^2}$、$Q=C\varepsilon$、$D=U-Q$、
$R=2\mu_{\rm num}Q/D$ 重组。$\mu_{\rm num}$ 是普通双精度乘积，不是精确实数平方。
$E_v,E_n$ 与保存值的相对差不超过 $2.854\times10^{-16}$；
两个分母均正。NumPy汇总得到FMM主 $R=7.063227413047822\times10^{-10}$，
direct主 $R=7.060452485709059\times10^{-10}$，与MATLAB仅有舍入差异。
独立汇总的两路质量相差 $4.16\times10^{-17}$，MATLAB保存的两路质量逐位相同。

同场两路 $R$ 绝对差约 $2.7749273388\times10^{-13}$，相对差约0.039287%，
相对差分母取两者绝对值之大者。微小lead法向平方分项的相对差约25.1%，但绝对差为
$6.64\times10^{-29}$，不能只按相对差否定结果。完整分项见实验README和raw MAT。

最强限制是512诊断 $R=4.0355781662571026\times10^{-10}$ 与主值相差42.86495%；
中心材料normal平方从native层约 $2.40\times10^{-30}$ 变为768层约
$2.04\times10^{-24}$。这排除“后处理评价已收敛”的解释，不阻断预先指定768层的数值交付。
新主值较历史run-05大约0.1569%；候选与构场/评价路径同时改变，不作单因素归因。

## 3. 原始矩阵与消去敏感性

从保存的散射与QZ块重建 $T,N_0$ 差为零；$A_{\rm def},A_{\rm phys}$ 的相对
Frobenius差分别为 $2.92\times10^{-16}$、$3.02\times10^{-16}$。
独立NumPy SVD与MATLAB四指标的绝对差为：

| 指标 | 绝对差 |
|---|---:|
| `adef_sigma` | 9.64589e-16 |
| `adef_ratio` | 1.59654e-18 |
| `aphys_sigma` | 7.05389e-17 |
| `aphys_ratio` | 2.47005e-17 |

跨BLAS从矩阵重新计算center raw action，最大绝对差约 $5.6\times10^{-15}$；
native层相对差约0.804，768两路约0.00169。独立重算的lead／wall有限项
$40\times2$账目数组的整体Frobenius相对差分别不超过
$1.89\times10^{-16}$、$7.26\times10^{-4}$；两分量lead／wall尾项向量的整体
2范数相对差分别不超过 $8.21\times10^{-16}$、$2.49\times10^{-4}$。
这些相对差的分母为两路范数之大者，不是逐行或逐分项相对误差上界。
它们反映微小差值的消去及运算次序敏感性；不能用 `max(1,norm)` 掩盖相对差，
也不能将保存样本汇总的一致性写成独立高精度残差认证。

## 4. 运行、修复与资源

run-01在MATLAB启动前因沙箱禁止 `ps` 而失败。run-02的单目标pairmat形状问题经
实验内“复制相同目标、保留首行”修复；两评价器共用，主质量32-target批量不进入分支。
公共包未改，旧cone中心诊断不能视为已无缺陷。run-02日志保持原样，后续预算明确计入
其63.302005秒，不用重新运行重置科学预算。

run-03进程353.322944秒，含失败累计416.624949秒；1479条监控记录的峰值
process-tree RSS为1,442,856,960 bytes，低于2 GiB，无外部MATLAB，退出cleanup干净。
168次FMM回调全部 `ier=0`。完整阶段时间和线程设置见实验README；没有同工作量直接法
基线，不从历史单点加速比外推本轮整体速度。

CSV的格式占位符错误在完成后修复：保留原CSV，从已保存JSON重导；raw MAT和执行快照不变，
没有追加科学运行。Skeptic首次 `/usr/bin/time -l` 的Python审计已完成，但随后
`sysctl kern.clockrate` 权限错误使外层命令退出1，首次审计RSS不可得；不计为科学失败。
主代理随后仅重放保存的审计脚本并用 `resource.getrusage` 记录，退出0：约1.70秒、
Python进程峰值1,908,654,080 bytes，低于2 GiB；该读后审计资源与MATLAB进程树分开记录。
运行使用已有NumPy，无新依赖。机器结果为
`test/i8/fmm-est-v1/output/attempt-1/run-03/skeptic-audit.json`。

## 5. 分类与移交

- **blocker：无。** 新场、完整同场账目、正分母、直接评价对照及原始重组均可解释。
- **important caveat：** 512/768未建立评价收敛；固定场对照未排除构场FMM误差；微小跳跃
  有消去敏感性；几何、求积、MFS及观察尾项仍无单侧包围。这些限制阻断更强认证或精度主张，
  不阻断本轮 `UNCERTIFIED_RNUM`。
- **minor caveat：** 操作修复和本机接口/线程适用性；模型创建参数可见，运行时模型遥测不可得。

唯一问题账目为 [[research/projects/eig-apost/implementation/i8/README|I8 README遗留问题表]]
中的 I8-Q2、I8-Q10、I8-E1/E2/E3。不在本轮追加网格、直接构场或认证工程。
第二阶段完成后停止；不重新定位、扫描或开展新阶段。
