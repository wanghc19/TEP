# Goerisch 第 2 版：可复用计算流程与成本拆分

R 指 reconstructed trial（重构试探场），D 指 direct tapered trial（直接截断有限元场），FEM 指 finite element method（有限元法），DtN 指 Dirichlet-to-Neumann，RT 指 Raviart–Thomas 通量空间，RSS 指 resident set size（驻留内存）。JSON 指 JavaScript Object Notation，CSV 指 comma-separated values。`goerisch-v2` 是 Goerisch 实验的第 2 版。

本阶段完成两条路线的计算复用和正式计算／额外核查计时拆分。使用原 control 输入和稳定 RT3，**R 的区间窄 19.08 倍，含启动正式计算贵 5.07 倍；加上额外核查后贵 7.70 倍。** 这只是同一粗层输入下的比较；等精度加密见 [v3](../goerisch-v3/README.md)。结果使用普通浮点，沿用 v1 的谱假设，谱隙端点尚未认证。

## 计算和计时边界

`goerisch_pipeline.m` 提供 `prepare`、`solve`、`evaluate`、`verify`、`audit` 和 `cache_check`。准备阶段读取 native 系数；R 还读取源矩，构造闭式系数，并计算归一化、尾项、拟合几何与 16 阶主积分点场值。组装、通量求解、逐点积分和审计复用主场值。两条路线都采用紧凑消元，大数组只留在内存。

正式计算包含读取已有输入、系数构造、归一化、主场值、组装、求解、逐点 $J$、基本符号／迹／求解检查和标量输出。含启动计时从 MATLAB 启动前到 `production.json` 写出；另列 MATLAB 函数内计时。

额外核查评价**同一通量**的 24 阶积分、归一化与面积，另做分项审计、缓存抽样、不兼容键拒绝及核查前后状态一致性检查，不重新求通量。24 阶点需要新的场值。启动、最终输出、退出与监测开销另列，不重复相加。

输入键包含路径、层级、源分辨率、相位、材料、形状、几何、求积、试探场、截断区间和位移。准备数据在内存存续期间视为不变。接口支持 RT1–4 复用，但本轮只测 RT3，未测多次数或热缓存加速。R/D 各用一个新的 MATLAB 进程、两个计算线程，没有清空操作系统文件缓存。

## 实测结果

| 路线／运行 | 含启动正式计算 | 额外核查 | 两者合计 | 进程监测总耗时 | 峰值 RSS | 区间宽度 |
|---|---:|---:|---:|---:|---:|---:|
| R／003 | 144.383 秒 | 289.270 秒 | 433.653 秒 | 441.713 秒 | 1.995 GiB | $1.886322755448\times10^{-7}$ |
| D／001 | 28.467 秒 | 27.858 秒 | 56.324 秒 | 61.668 秒 | 2.146 GiB | $3.598887144879\times10^{-6}$ |

MATLAB 内正式计算 R/D 为 136.420/17.886 秒，比值 7.63；进程总耗时比 7.16。每条路线只有一次成功测量。

| 路线 | $q$ | $J$（16 阶） | $J$（24 阶、同一通量） | Gram $J$ | 区间 |
|---|---:|---:|---:|---:|---|
| R | 3.4287286994656423 | 0.29165329083928782 | 0.29165329084456976 | 0.2916532908414412 | [2.4287286271215778, 2.4287288157538551] |
| D | 3.4287292322708147 | 0.29165329083347658 | 0.29165329083347669 | 0.29165329083563263 | [2.4287278520291640, 2.4287314509163074] |

主场值计算 R/D 为 119.02/2.69 秒；R 的高阶点场值另需 264.28 秒。每条路线主点有 408 批、44,225,536 个值，组装、逐点评价、审计和核查后复查各复用一次；高阶核查另评价 99,507,456 个值。旧 v1 的 R 已有主场值缓存，v2 保留了这项复用，并让 D 同样使用缓存。

分开计时没有把旧约 432 秒的完整 R 流程缩短成 144 秒。所有互不重叠的分项见 [timings.csv](timings.csv)，总表见 [benchmark.csv](benchmark.csv) 和 [summary.json](summary.json)。计时分项与外部时钟对账误差小于 0.016 秒，低于预设 max(0.1 秒, 1%)。

## 必需检查

| 检查 | R | D | 容差／结果 |
|---|---:|---:|---|
| $q$ 相对原 RT3 的相对差 | 0 | 0 | $10^{-12}$；通过 |
| 宽度相对差 | $5.167274\times10^{-8}$ | $2.708378\times10^{-9}$ | 0.005；通过 |
| $J$ 相对原值的缩放差 | $6.643942\times10^{-8}$ | $3.482360\times10^{-9}$ | 0.01；通过 |
| Gram／逐点 $J$ 缩放差 | $8.591060\times10^{-4}$ | $4.508495\times10^{-5}$ | 0.01；通过 |
| 两种宽度公式绝对差 | $1.808821\times10^{-15}$ | $1.471192\times10^{-15}$ | $10^{-13}$；通过 |
| 24／16 阶 $J$ 缩放差 | $2.107259\times10^{-3}$ | $2.321573\times10^{-9}$ | 0.01；通过 |

缩放量为 $q|\Delta J|/(qJ-1)$；与旧基准比较时用旧基准分母。两路线的 $qJ-1$、Gram 分母、$\kappa$ 符号及 BIE 数值参考 $2.428728670022710$ 的包含检查通过。BIE 只作参考，不作为真值证明。

法向迹误差约 $8.24\times10^{-14}$，全局求解残差低于 $1.23\times10^{-15}$，单元残差低于 $1.83\times10^{-12}$。16／24 阶最大包含物面积相对误差为 $2.66\times10^{-15}$／$8.58\times10^{-16}$，单元面积误差不超过 $1.56\times10^{-14}$，均低于 $10^{-12}$。

R 复现 Rayleigh 商与非加权范数；两个分子公式相对差 $3.82\times10^{-15}$，外部质量上界相对全条带质量低于 $1.83\times10^{-11}$。归一化的 x 阶数变化引起 $\theta$ 变化 $-2.665\times10^{-12}$，y 阶数变化为 $4.44\times10^{-16}$。核查前后 $q,J$、区间和通量系数完全相同；R 重构系数也逐项相同。32 个模板点跨 13 个胞元的 416 个值与缓存相对差为零；六种不兼容配置均被拒绝。

经理已从原始 JSON 独立重算关键数字和比值，并检查计时及保护目录。原始证据见 [D](output/run-001/science/result.json)、[R](output/run-003/science/result.json) 及各运行的 `monitor.json`、`launcher.json`。

## 固定参数与上游成本

通量区域为 $[-13.5,13.5]\times[-0.5,0.5]$，左右各 13 个胞元；$\beta=0.5$、$\gamma=1$，未平移谱隙端点为 $1.3174^2$、$2.1875^2$。使用原解析界面拟合网格、稳定 RT3、Piola 变换和 16／24 阶积分，每批 48 个三角形。左／中／右模板有 6410／6330／6392 个三角形，材料取 1／4／17。R 使用原 33 胞元源区域上的 control 分辨率 $N=256,M=128$ 并包含解析外尾；D 使用 $|x|\le11.5$ 为 1、$|x|\ge13.5$ 为 0 的原余弦截断。

显式输入目录为 `/Users/whc/Documents/Work/epost/test/i9/dtn-bound-v1/output/attempt-1/run-03`。只读取 `native.mat` 的 `native`，源块的 `F_b*`、`dF_b*`、`cols`，不加载 `V_b*` 代理数据。

共同 FEM/DtN 求根成本未测；R 专用源矩生成也未包含。本轮已计入源块读取和闭式系数构造。历史 I9.6 native adapter 用时 2.550206 秒，control 层共 105.487019 秒，其中还含认证积分、聚合、修正、范数与存储，不能当作最小普通源矩生成成本直接相加。历史分项见 [upstream-ledger.json](upstream-ledger.json)。因此本轮不提供从头生成输入的完整成本比。

## 运行记录与预算

运行前 D 完整预算低于 180 秒、2.7 GiB；R 低于 600 秒、2.9 GiB；合计低于 13 分钟。统一软／硬限 30／40 分钟、3 GiB。

- `run-001`：D 成功，61.668 秒。
- `run-002`：R 在源数据清单检查中误以为 `left_s0000_corr.mat` 必定存在，20.484 秒后停止，尚未组装通量。数值读取本来允许缺少修正块；只修复清单选取，不改数值公式。失败日志保留。
- `run-003`：R 成功，441.713 秒。失败后预算继续累计，未重置。

全部计算共 523.866 秒，最大 RSS 2.146 GiB。无大缓存或新 MAT 输出。监测器的 `peak_experiment_disk_mb` 指其自身 diagnostics 目录；本实验存储另列于 `scope-resources.json`。

## 复现与文件

依赖 Python 3、MATLAB R2023b；通过原 `diagnostics-v1/monitor.py` 运行，按执行权限流程申请。以下是历史实际运行命令；再次运行必须使用新的输出目录，并遵守届时授权和预算。

```sh
python3 test/numerical-directions/goerisch-v2/launch_pipeline.py --input /Users/whc/Documents/Work/epost/test/i9/dtn-bound-v1/output/attempt-1/run-03 --output test/numerical-directions/goerisch-v2/output/run-001 --monitor test/numerical-directions/diagnostics-v1/monitor.py --trial D
python3 test/numerical-directions/goerisch-v2/launch_pipeline.py --input /Users/whc/Documents/Work/epost/test/i9/dtn-bound-v1/output/attempt-1/run-03 --output test/numerical-directions/goerisch-v2/output/run-003 --monitor test/numerical-directions/diagnostics-v1/monitor.py --trial R
python3 test/numerical-directions/goerisch-v2/summarize_pipeline.py --direct test/numerical-directions/goerisch-v2/output/run-001 --reconstructed test/numerical-directions/goerisch-v2/output/run-003 --output test/numerical-directions/goerisch-v2
```

最后一条仅重算已保存标量。上游输入生成方法见受保护 I9.6 README：`run_bound.py --mode formal --matlab /Applications/MATLAB_R2023b.app/bin/matlab --output <new-directory>` 及其 formal 配置、输入运行保存的源代码。本阶段没有重新生成上游输入；源块保留在 epost，只读访问。

数值源码为 `goerisch_pipeline.m`、`pipeline_reconstruction.m`、`goerisch_fitted_geometry.m`、`pipeline_benchmark.m`；入口为 `launch_pipeline.py`。复制来源是 v1 的对应实现。`build_pipeline.py`、`pipeline_helpers.txt`、`write_report.py` 为初始开发记录，不是数值运行依赖；旧报告生成器输出英文工作记录，不用于覆盖经理整理后的本文。

每次运行保留命令、日志、资源采样、监测和标量结果，失败证据也保留。随本阶段提交紧凑 JSON／CSV／日志，便于在不运行 MATLAB 的情况下复核；大输入不纳入提交。v1、theta-v1、test/i9、test/i10、共享包和监测器未修改，没有写入其他 worktree。
