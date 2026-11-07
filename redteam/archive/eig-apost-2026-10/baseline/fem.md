# FEM + DtN 基线

日期：2026-10-28。位置：`/Users/whc/Documents/Work/epost`，分支 `codex/epost`，审计时版本 `e1866b7`。本记录直接读取实现、运行配置和原始结果；未重跑生产求解。理论审计见 [[redteam/theory/fem-audit]]。

## 1. 实际对象及入口

当前接近 BIE 至 $10^{-12}$ 的候选来自 **I10.1 formal run-02 的 g48/P4/check**，被 I10.2 复用；不是旧 I9.3 截断 FEM，也不是 I9.5b 原候选。

| 项 | 源或值 |
|---|---|
| 原生产入口 | `test/i10/enrich-v1/enrich_i101.m`，`enrich_i101(output_dir,'formal')` |
| 原运行目录 | `test/i10/enrich-v1/output/attempt-1/run-02/` |
| I10.2 入口 | `test/i10/refine-v1/refine_i102.m`，`refine_i102(output_dir,group)` |
| I10.2 新运行 | `test/i10/refine-v1/output/attempt-1/run-g24-01/` |
| 理论 | `research/projects/eig-apost/phase3-analysis/fem-bound/s-enrich.md`，I10.1-A，命题1、命题2、定理3 |
| 当前输出身份 | `CONDITIONAL_ON_SATURATION_AND_EVALUATION`; `S_verified=false`; `E_certified=false` |
| 版本检查 | 当前 `enrich_i101.m` 与 g48 运行目录内 `source/enrich_i101.m` 字节一致；只检查文件身份，未据此宣称计算正确 |

`refine_i102.m` 继承 I10.1 核心，二者不是独立实现。两者的源头又是 I9.5b 的网格、QP 约束、Schur/QZ、分支求根实现（`enrich_i101.m:35–48`）。FEM 数值入口内没有 `bloch.*`、`kernel.*`、`op.*`、MFS 或 BIE 函数调用；几何及物理约定、DtN 稳定图思想仍可共有。BIE 数字在汇总阶段加入，不能因此把整个研究设计称为盲测。

## 2. 物理模型和离散参数

条带 $B=\mathbb R\times(-1/2,1/2)$，$d=L=1$，$\beta=0.5$，$u(x,1/2)=e^{\mathrm i\beta}u(x,-1/2)$。求解

$$
-\Delta u=\mu\rho u,\qquad \mu=k^2,
\qquad a(u,v)=\int_B\nabla u\cdot\nabla\overline v,
\qquad b(u,v)=\int_B\rho u\overline v.
$$

中心 $(-1/2,1/2)^2$ inclusion 的参数曲线为

$$
\gamma_0(t)=0.2\big((1.5+0.3\cos 5t)\cos t,\ (1+0.3\cos 5t)\sin t\big),
\qquad \rho_{\rm center}=4.
$$

左右胞元中 inclusion 以对应整数胞元中心平移，径向函数为

$$
r_\pm(t)=\frac{0.2(1+a_\pm\cos3t)}{\sqrt{1+a_\pm^2/2}},
\qquad a_-=0.12,\quad a_+=0.20,\qquad \rho_-=\rho_+=17.
$$

背景材料为1。左右几何不同，不应作左右镜像假定。来源：`refine_i102_config.m:22–32`；`refine_i102.m:676–703`。

g48 使用每边48个背景细分、每条材料曲线320段、二次几何映射；场阶 $p=2,3,4$ 同时用于中心和两侧。共有19132个三角形、38649个二次几何节点；P4 的左/中心/右自由度为51472/50832/51328，每面独立墙迹维数192。主/检查积分是体 Gauss–Duffy 12/16阶及薄带参数细分2/4、Gauss点8/12。真实质量由名义质量加有向薄带修正；没有把曲边近似材料永久当成真材料。来源：运行 `config.json`、`result.json.geometry/spaces` 及 `refine_i102_config.m:61–82`。

## 3. 基线数值

| 配置 | 最终 $k$ | 最终 $\mu$ | 条件 $B_4$（$\mu$） | 条件最大 $k$ 半径 |
|---|---:|---:|---:|---:|
| g12/P4/check | 1.5584378957007303 | 2.4287286747561203 | $4.1416429883161215\times10^{-7}$ | $1.3287803050437242\times10^{-7}$ |
| g24/P4/check | 1.5584378942105757 | 2.4287286701114934 | $1.3837233112259627\times10^{-8}$ | $4.43945606795503\times10^{-9}$ |
| g48/P4/check | 1.5584378941804409 | 2.428728670017567 | $9.802887142498548\times10^{-10}$ | $3.145100353403209\times10^{-10}$ |

g12 原始路径是 `test/i10/enrich-v1/output/attempt-1/smoke-03`；g24/g48 路径见上。表中 g12/g24 从 `test/i10/refine-v1/output/attempt-1/summary-01/science.json` 定位，g48 已直接核对其原始 `result.json`。这些是历史结果读取，不是本次重测。

g48 的 $\widetilde\nu_3=2.428728670697856$，故 $d_{34}=6.802887142498548\times10^{-10}$。半径公式是

$$
B_4=d_{34}+\epsilon_3+2\epsilon_4,
\qquad \epsilon_3=\epsilon_4=10^{-10},\quad q=1/2.
$$

其中 $3\times10^{-10}$ 是输入的评价预算，不是测出的严格误差。原始输出的饱和诊断比为 $0.0012114310029493385$；它不是饱和条件的证明。P4 主/检查规则根差及最终 $\mu$ 括区宽均为 $5.349498621853854\times10^{-12}$。这与声称的 BIE/FEM 末位差处于相近尺度。

g48/P4 的关键原始诊断：

| 诊断 | 左端 | 右端 |
|---|---:|---:|
| 最大稳定 multiplier 模 | 0.37710494369862624 | 0.38393566495815923 |
| QZ 单位圆距离指标 | 0.4523221408445481 | 0.44515388297364694 |
| 稳定图 $Z_0$ 的 `rcond` | 0.0058912064413843435 | 0.0059593219312544625 |
| Riccati 相对残差 | $1.04336\times10^{-15}$ | $1.13198\times10^{-15}$ |
| 完整 lead 质量 | 1.0353424051951339 | 1.048645887981178 |

中心质量2.6390227263281134，总质量4.723011019504425。这里归一化的是墙质量 $g^*Wg=1$，不是全场 $L^2_\rho$ 已归一化。原始 `center_residual=1.5917261198246105e-12` 是有限矩阵相对残差，不能直接读作连续谱距离。来源：g48 `result.json.layers[2].recovery`。

## 4. 成本和可复用数据

g48 历史完整 launcher 墙钟127.844845秒，MATLAB函数109.3254006667秒，进程树采样峰值2,508,603,392字节。g24 历史 launcher 墙钟39.606100708秒，采样峰值1,711,964,160字节。来源：各运行的 `resource.json`、`timing.json`。g48 使用历史3,000,000,000字节上限，已超过本次 redteam 的2 GiB上限；本次不能未经重新估算直接重跑。以上成本不证明同可信误差下优于 BIE。

可重建现有场所需原始数据已经保存：`evidence.mat`（网格、空间、嵌入）；`layer-P4-check-matrices.mat`；`recovery-P4-check-center.mat`（`u_free,g,F,H,S,lambda_all,k,mu`）；左右 `recovery-P4-check-*.mat`（`B_interior,Pout,S,D,multipliers,G,X,k,mu`）。lead 第 $j$ 胞元的墙迹是 $P^{j-1}g$，内部系数是 `B_interior` 乘该近墙迹。使用这些数据构造对照仍依赖生产求解器，只能独立检查重建和比较环节。

## 5. 本次检查界限

已读源码、配置、原始JSON和来源PDF；已核对生产源码快照身份。未调用 MATLAB/Octave 求解器，未宣称执行数值重算。原始生产文件未修改。所有新的分析只写入本目录所属 redteam 文件。
