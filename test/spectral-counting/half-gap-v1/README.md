# 单胞夹逼认证半条带 Dirichlet 谱隙

理论见 [[research/explorations/spectral-counting/s-half-gap]]。实际切口为 $x=\pm1/2$，不满足竖直反射对称。本实验分别认证单胞 Dirichlet 第一特征值上界与 Neumann 第二特征值下界，再由任意整胞有限截断夹逼和半条带弱极限获得 G2。

执行前预算：首选 $a_0=2.30,b_0=2.60$、$N=4,M=2$（25维）；最多 $N=6,M=3$（49维）。预计完整计算少于1分钟、0.2 GB；科学硬限30分钟或09:10 UTC较早者，进程峰值预停1GB，仓库占用900MB预停。主仓库当前约93MB，预留本实验输出不超过5MB。只使用已有 Conda `octave` Python 与 `gap-v1/vendor`，串行单线程、不启动MATLAB、不输出 `.mat`。所有新输出在本目录 `attempt-1/`；不会覆盖 G1 证书。

验收：真实半整数材料矩有可靠余项，(D5)严格低于 $a_0$，正尾和修正界外向包围，(D7)的有限矩阵可靠惯性恰为1负且无零；两侧均成功才关闭 G2。普通可行性结果不得冒充可靠证书。

## 实际可靠结果

2026-10-30 首次配置已通过，`attempt-1/certify-01.json` 状态 `HALF_GUIDE_DIRICHLET_GAP_PROVED`。两种材料积分均在192 bit Arb下计算：256点解析梯形余项＋可靠合同，64次极坐标 Taylor 余项＋球 LDL；它们共享矩阵装配、Arb 后端及 G1 已验收的符号函数，不称为完全独立软件后端。

| 项目 | 左端 | 右端 |
| --- | ---: | ---: |
| $\alpha$ | $3/25$ | $1/5$ |
| 第一 Dirichlet 本征值可靠试探上界 | 约2.180745080372 | 约2.188158712948 |
| Neumann 修正有限块负惯性 | 1（两算法相同） | 1（两算法相同） |
| 矩阵维数 | 25 | 25 |
| 所需半整数材料矩 | 45 | 45 |

二者严格满足 $\lambda_1^D<2.30$、$\lambda_2^N>2.60$。HD1 的任意有限整胞夹逼与半条带弱极限因此给实际切口的 $[2.30,2.60]$ 排谱；对目标 $[2.40,2.46]$，由有理端点差得到统一谱距至少 $1/10$。这仍不证明缺陷中心的导模数。

主记录包含可靠 dyadic 端点及两侧全部 LDL 枢轴；`certify-01-moments.json` 保存两种材料矩。`rational-checks.json` 用 Python 标准库的精确有理数重新检查保存的试探值、符号余量、50个枢轴及有理端点差；它不替代几何积分的解析余项证明。stdout 在 `certify-01.txt`。进程峰值53,526,528 bytes，模块载入后记录0.186秒；仓库监测约92.5MB，没有MATLAB运行。

## 复现

只依赖 Python、NumPy/python-flint，以及已验收 `gap-v1/` 的预算、格式和惯性函数；不读取人类报告作为运行前提。当前实现仅新建一个源码文件 `half_gap.py`，没有改动 G1 源码或证书。

```sh
source /Users/whc/opt/miniconda3/etc/profile.d/conda.sh
conda activate octave
export PYTHONPATH="$PWD/test/spectral-counting/gap-v1/vendor:$PWD/test/spectral-counting/gap-v1"
export PYTHONDONTWRITEBYTECODE=1
export OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1
export TMPDIR="$PWD/test/spectral-counting/half-gap-v1/tmp"
python test/spectral-counting/half-gap-v1/half_gap.py \
  --nx 4 --my 2 --a0 2.30 --b0 2.60 --storage-root "$PWD" \
  --output test/spectral-counting/half-gap-v1/attempt-1/certify-replay.json
```

本轮实际运行还设置 `--deadline-utc 2026-10-30T09:10:00`；未来复现设置当次截止或省略。输出必须新命名；旧证书不覆盖。第一可靠配置已通过，没有增加到49维、启动新 attempt 或改变几何。失败路线仅为已严格排除的切口反射捷径。

理论和输出的独立人工验收状态见 [[research/planning/review-3h-20261030]]；尚不自行把单胞充分判据或软件成功出口当作人工审查已完成。
