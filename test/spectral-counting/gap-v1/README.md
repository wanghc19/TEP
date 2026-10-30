# 两侧真实周期胞元的 Fourier 谱隙实验

本实验对应 [[research/explorations/spectral-counting/s-gap-fourier|F1–F5]]；主程序不会读取 Markdown、Git 或历史数据作为运行前提。复算器读取本实验的 JSON 作为待核查数据，另行构造真实材料矩与惯性。目标为当前两侧三叶形、固定 $\beta=0.5$ 和 $\mu\in[2.40,2.46]$ 的完整 Floquet 参数覆盖。

## 执行前预算与验收

- 所有实现、依赖、日志、临时文件和结果位于本目录。复用 `attempt-1`，本轮不产生 `.mat` 或大矩阵文件。
- 只使用 Conda `octave` 的 Python；缺少的 NumPy/python-flint 安装到本目录 `vendor/`，不改全局环境。依赖预计不超过 150 MB，数据与日志不超过 10 MB；每次大写前重测仓库总占用。
- 未启动 MATLAB；其总占用保护未建立，不执行旧 MATLAB 启动器。
- 初始 Fourier 截断 $N\le5$，至多 121 维复 Hermitian 矩阵；串行、单 BLAS 线程。普通小规模可行性阶段预计少于 2 分钟、0.3 GB。
- 完整可靠计算计划不超过 30 分钟；本实现选择在 30 分钟直接中止，不使用额外宽限。通过显式 `--deadline-utc` 设置本轮 09:10 UTC 截止，通过 `--storage-root` 在启动、每次 JSON 写入前及运行中监测仓库；900 MB 提前停止，单个 JSON 不超过 10 MB。内存预算 1 GB，采用有界小矩阵和进程峰值监测；不是操作系统硬内存隔离。
- 先核对解析证明与成本，再执行普通可行性检查，最后可靠真实几何积分、有限符号、遗漏方向和完整参数覆盖。普通数据与可靠数据分别标记。
- 成功必须给两侧每个子区间的可靠通过余量；否则记录哪项不等式失败。节点无谱、阶次稳定、普通残差小均不替代成功判据。

## 复现与结果

2026-10-30 实际通过。`attempt-1/certify-02.json` 的状态为 `COMMON_PROJECTED_GAP_PROVED`；`audit-02.json` 为 `INDEPENDENT_GEOMETRY_AND_LDL_AUDIT_PASSED`。前者用 128 bit Arb、256 点解析梯形余项和可靠合同；后者用 192 bit Arb、64 次极坐标 Taylor 余项和球算术 $LDL^*$。两者共享 Arb 后端，不能称为两个软件后端的独立认证。

| 项目 | 保存结果 |
| --- | --- |
| 精确模型 | $\alpha=3/25,1/5$，$\rho=1+16\mathbf1_D$，$r_0=[5\sqrt{1+\alpha^2/2}]^{-1}$，$\beta=1/2$ |
| Fourier 截断 | $N=2$，25 维；所有遗漏模态由显式正尾控制 |
| 参数覆盖 | 两侧各 16 个闭子区间，完整 $[-\pi,\pi]$；共 64 次有限惯性判定 |
| 两阈值负惯性 | 每侧、每格均为 $1/1$ |
| 扩张节点区间 | $a_*\approx1.83018634079571$，$b_*\approx3.11447758493362$ |
| 正尾／Schur 修正 | $h\approx194.043991083362$，$\delta\approx3.199264850540$ |
| 最小合同严格占优余量 | $0.7711806959846429$，验收使用精确 dyadic 下界而非此显示值 |
| 独立材料矩复算 | 每侧 25 个矩全部相交；圆形极限 9 个矩与 Bessel 恒等式相交 |
| 复算 Taylor 余项上界 | 左侧约 $4.44\times10^{-34}$，右侧约 $2.61\times10^{-32}$ |
| 资源 | 主计算记录 0.842 s／55,132,160 bytes；复算 0.236 s／55,033,856 bytes；这些计时从模块载入后起算，不含全部冷启动成本 |
| 仓库占用 | 验收期间约 91.7 MB，含依赖与隐藏／忽略文件，另预留 1 MiB 给 Git 指针；不跟随符号链接 |

结论是**连续二维周期端的共同谱隙**，不是采样无谱。F6 进一步给原有限缺陷波导在该区间无本质谱。尚不证明半条带 Dirichlet 无极点、缺陷导模存在、数量或简单性，也不认证旧场的误差半径。精确有理几何与历史 MATLAB 冻结的二进制几何执行值明确区分。

在仓库根目录，先激活环境并设置本地临时位置；这里没有 MATLAB 或 Octave 数值调用：

```sh
source /Users/whc/opt/miniconda3/etc/profile.d/conda.sh
conda activate octave
export PYTHONPATH="$PWD/test/spectral-counting/gap-v1/vendor"
export PYTHONDONTWRITEBYTECODE=1
export OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1
export TMPDIR="$PWD/test/spectral-counting/gap-v1/tmp"
```

依赖为 `requirements.txt` 中的 NumPy 2.5.4、python-flint 0.9.0，本轮使用 Python 3.14。若尚未安装，先建立本目录的 `vendor/`、`tmp/`，在资源预算内执行：

```sh
python -m pip install --no-cache-dir --target test/spectral-counting/gap-v1/vendor \
  -r test/spectral-counting/gap-v1/requirements.txt
```

正式命令如下。输出文件必须新命名；已存结果不覆盖。本轮曾增加 `--deadline-utc 2026-10-30T09:10:00`；未来复现应设置当次截止或省略这个可选参数。

```sh
python test/spectral-counting/gap-v1/gap_fourier.py certify \
  --cutoff 2 --cells 16 --nodes 256 --bits 128 --storage-root "$PWD" \
  --output test/spectral-counting/gap-v1/attempt-1/certify-replay.json
python test/spectral-counting/gap-v1/audit_gap.py \
  test/spectral-counting/gap-v1/attempt-1/certify-replay.json \
  --degree 64 --bits 192 --storage-root "$PWD" \
  --output test/spectral-counting/gap-v1/attempt-1/audit-replay.json
```

主程序自动保存同 stem 的 CSV、材料矩 JSON；stdout 可重定向到本目录内的文本日志。输出标量用精确 dyadic 端点保存，`display` 和 CSV 余量仅供阅读。复算器保存全部 64 个矩阵的可靠枢轴区间，不依赖 NumPy 本征向量。

## 过程与失败边界

- `probe-01.json` 仅是普通可行性检查：$N=1$ 的所有已试覆盖数未通过；$N=2$ 的 8 格也未通过，16 格通过。这说明充分判据在粗配置下不足，不说明实际谱隙不存在。没有为通过而调宽验收阈值。
- `certify-01`、`audit-01` 是首次可靠成功。`02` 仅在加入显式资源参数和输入合法性检查后重做验收；全部数学区间和有限符号记录逐项相同，见 `guard-checks.json`。未创建新 attempt。
- 非正条带宽度、已经过去的截止时间均在生成结果前拒绝，检查通过。普通网络环境首次安装依赖失败，获准的网络访问后安装成功；日志留在本 attempt，未改全局环境。
- MATLAB 总进程内存保护未建立，因此没有启动 MATLAB；本实验不依赖 MATLAB 专有数值语义，无待补 MATLAB 验收项目。
- 数学对应：`mass_balls` → F3，`certified_inertia` → F4，`certify` → F1/F2，`area_moments` 与 `ball_ldl` → F5。资源控制不参与数学充分判据。

独立人工审查见 [[research/planning/review-3h-20261030]]；唯一开放事项账目见 [[research/explorations/spectral-counting/STATUS]]。
