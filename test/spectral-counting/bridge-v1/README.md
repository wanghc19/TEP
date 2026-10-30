# 二进制解析模型与几何扰动族认证

执行前合同见 [[research/explorations/spectral-counting/s-model-bridge]]。将每个 inclusion 的对称差面积限制为 $10^{-10}$，两个目标端点扩成半径 $10^{-12}$ 的实区间，从数学常量重新构造 G2 与有限箱证明输入。质量矩在实、虚两方向增宽，允许扰动域不保留反射对称；不修改原证书或源码。

预计完整运行2分钟以内、0.5GB，输出不超过5MB；串行单线程、最多231维、192 bit Arb，30分钟与09:10 UTC较早者硬停。所有新文件在本目录，依赖已有 `gap-v1/vendor/`。不读取旧实验JSON，不运行MATLAB、不产生`.mat`；因此也提供从干净数学输入重现完整证明链的入口。

## 实际结果与范围

2026-10-30，`attempt-1/robust-01.json` 的状态为 `ROBUST_CONTINUOUS_MODE_COUNT_PROVED`。从常量重新生成两侧单胞材料矩及三类有限箱材料矩，重新检查半条带判据和8个有限箱界矩阵；没有读取已有科学结果。全部矩阵同时通过可靠合同与球 LDL，箱端点负惯性仍为 D/N 各 $6\to7$，最小合同余量约0.00581657。按 HD1、BC1–BC3 与 SC1，每个被覆盖的周期材料模型在目标窗中均恰有一个简单导模，两个端点带均无谱。

| 几何 | 字面量二进制解析模型的对称差面积上界 | 每个展开系数另允许 $10^{-13}$ 变化的面积上界 |
| --- | ---: | ---: |
| 左端 | $7.88\times10^{-17}$ | $2.044\times10^{-12}$ |
| 右端 | $1.205\times10^{-16}$ | $2.390\times10^{-12}$ |
| 中心 | $2.072\times10^{-16}$ | $4.148\times10^{-12}$ |

表中向上取整仅便于阅读；接受条件使用 JSON 中的精确 dyadic 端点。所有面积界均低于统一预算 $10^{-10}$，每个曲线同伦保持星形及胞内性。2.40、2.46 的 binary64 误差分别约 $8.89\times10^{-17}$、$3.56\times10^{-17}$，均被半径 $10^{-12}$ 的端点带包围。

`audit_literals.py` 只用 Python 标准库和精确有理数：核对每个十进制位于相邻 binary64 中点之间、中心系数恒等式、两端正根的平方不等式、面积／方向／胞内见证及全部1870个 LDL 枢轴、合同余量和端点尾界。`attempt-1/rational-01.json` 状态为 `BINARY_LITERALS_COEFFICIENTS_AND_ROBUST_SIGNS_VERIFIED`。它不重新执行矩阵分解或独立证明 Arb 输出本身；可靠积分和分解仍依赖公开 Arb/FLINT 实现。

已核对的源对象为 `test/i10/refine-v1/refine_i102_config.m` 与 `refine_i102.m` 的解析几何公式。本证书覆盖精确有理参数及这些源码 binary64 字面量的实数解析解释；**没有重放 MATLAB 的逐位运算、认证旧曲边网格或旧恢复场，也没有认证旧高精度误差半径**。固定 $\beta=1/2$，准周期相位为 $\exp(\mathrm i/2)$；结论是纤维条带的 $L^2$ 模态，不是全平面 $L^2$ 局域态。独立人工复核状态见 [[research/planning/review-3h-20261030]]。

## 完整复现

在仓库根目录执行以下命令。所需七份 Python 源码位于本主题四个实验目录；具体依赖安装命令和固定版本见 [[test/spectral-counting/gap-v1/README]]。`robust_count.py` 不读取保存的证书、Markdown 或 Git 元数据。`audit_literals.py` 仅读取刚产生的结果作为待验证见证。输出名须未存在；下列 `replay` 文件本轮没有额外生成。

```sh
source /Users/whc/opt/miniconda3/etc/profile.d/conda.sh
conda activate octave
mkdir -p test/spectral-counting/bridge-v1/attempt-1 test/spectral-counting/bridge-v1/tmp
export PYTHONPATH="$PWD/test/spectral-counting/gap-v1/vendor:$PWD/test/spectral-counting/gap-v1:$PWD/test/spectral-counting/half-gap-v1:$PWD/test/spectral-counting/box-count-v1"
export PYTHONDONTWRITEBYTECODE=1
export OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1
export TMPDIR="$PWD/test/spectral-counting/bridge-v1/tmp"
python test/spectral-counting/bridge-v1/robust_count.py \
  --storage-root "$PWD" \
  --output test/spectral-counting/bridge-v1/attempt-1/robust-replay.json
python test/spectral-counting/bridge-v1/audit_literals.py \
  test/spectral-counting/bridge-v1/attempt-1/robust-replay.json \
  --output test/spectral-counting/bridge-v1/attempt-1/rational-replay.json
```

本轮实际文件名为 `robust-01`、`rational-01`；主命令另设置 `--deadline-utc 2026-10-30T09:10:00`，两个 stdout/stderr 日志均在 `attempt-1/`。未来复现应设置新的截止时间或省略该可选参数。必须检查上述成功状态及严格符号数据，不能仅检查 shell 退出码。

主计算模块载入后46.441秒、进程峰值288,866,304 bytes；写结果前仓库预算95,382,880 bytes。计时不包含全部冷启动。完整结果在预定2分钟／0.5GB／5MB预算内；串行、无MATLAB、无`.mat`。算法、先前证书及旧求解器均未修改。本次只有一个成功配置，没有另起 attempt。
