# 有限箱夹逼无限导模计数

执行合同对应 [[research/explorations/spectral-counting/s-box-count|BC1–BC3]]。G1/G2 的已提交与已验收证书保持不变。本实验在当前真实五瓣中心和三叶形两端的有限箱上，分别认证 Dirichlet、Neumann 两种外墙条件在 $\mu=2.40,2.46$ 的完整连续惯性；只有同端点两种边界条件的整数相同，才按 BC3 提升。

预算：先做普通可行性探针，$L=1,2,3$ 个 lead 胞元／侧、纵向截断 $N=16,24,32$、横向 $M=3$，最大231维。主可靠计算仅执行首个通过的配置，192 bit Arb、256点解析求积。预计探针少于10秒，完整可靠计算少于5分钟，峰值小于0.5GB；硬限仍为30分钟或09:10 UTC较早者，1GB进程峰值预停、900MB仓库占用预停。当前仓库约93MB，本目录输出预算10MB。串行单线程、无MATLAB、无`.mat`，本次方法全程复用 `attempt-1`。

有限符号采用矩阵协方差尾修正 $e^2(R_2-R^2)/h$。不能对三值材料误用两值恒等式；不能只报 Galerkin 矩阵惯性。若所有预算内配置均不能可靠分离或边界条件整数不同，保留明确未完成状态，不扩大到不可控规模。

## 已保存的可靠有限输入

首个通过普通判据的配置为 $L=3,N=32,M=3$；箱长7，真实中心及两侧各3胞。随后192 bit可靠主计算和不使用梯形节点的 Laurent–Taylor 材料矩复算都通过。

| 外墙条件 | $\mu$ | 维数 | 未修正／协方差修正后的可靠负惯性 | 最小合同占优余量 |
| --- | ---: | ---: | ---: | ---: |
| Dirichlet | 2.40 | 224 | 6／6 | 0.0263971578 |
| Dirichlet | 2.46 | 224 | 7／7 | 0.0517132883 |
| Neumann | 2.40 | 231 | 6／6 | 0.005846398855 |
| Neumann | 2.46 | 231 | 7／7 | 0.0720447546 |

主记录 `attempt-1/certify-01.json` 状态为 `CONTINUOUS_BOX_ENDPOINTS_PROVED`：每个上下界矩阵同时通过可靠合同和球 LDL。`certify-01-moments.json` 保存三种真实材料各455个矩。显示余量不是连续谱距，验收使用精确 dyadic 下界。

`audit-01.json` 状态为 `LAURENT_GEOMETRY_AND_BOX_LDL_AUDIT_PASSED`：用 B7 的96次有限 Laurent–Taylor 展开重建全部1365个矩，其余项由真实相位积分界给出；重装8个矩阵后球 LDL 全部通过。它不使用节点、复条带宽度或梯形余项，但共享物理模型、矩阵装配和 Arb 后端。`rational-checks.json` 另以标准库有理数检查主／复算各1820个严格定号枢轴及全部合同余量。不能仅由两种矩包围相交推断正确，可靠性分别依赖各自余项和严格符号。

BC3 若接收，减去6个 lead 单胞内部负方向后，连续完整中心的两端惯性为 $0\to1$。独立数学与输出审查状态见 [[research/planning/review-3h-20261030]]；这里不把有限整数差的程序标签单独当作无限计数证明。

## 资源、复现及失败配置

主计算模块载入后9.946秒、峰值264,142,848 bytes；独立几何复算45.711秒、峰值209,469,440 bytes。两者顺序运行，计时不包含全部解释器冷启动。加普通探针仍在单次30分钟预算内；没有MATLAB、Octave数值运行、并行池或`.mat`。本目录输出约2.61MB，运行期间仓库约95MB。

```sh
source /Users/whc/opt/miniconda3/etc/profile.d/conda.sh
conda activate octave
mkdir -p test/spectral-counting/box-count-v1/tmp
export PYTHONPATH="$PWD/test/spectral-counting/gap-v1/vendor:$PWD/test/spectral-counting/gap-v1"
export PYTHONDONTWRITEBYTECODE=1
export OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1
export TMPDIR="$PWD/test/spectral-counting/box-count-v1/tmp"
python test/spectral-counting/box-count-v1/box_count.py certify \
  --length 3 --nx 32 --my 3 --storage-root "$PWD" \
  --output test/spectral-counting/box-count-v1/attempt-1/certify-replay.json
python test/spectral-counting/box-count-v1/audit_box.py \
  test/spectral-counting/box-count-v1/attempt-1/certify-replay.json \
  --storage-root "$PWD" \
  --output test/spectral-counting/box-count-v1/attempt-1/audit-replay.json
```

本轮两个命令均另外设置 `--deadline-utc 2026-10-30T09:10:00`。未来复现应设当次截止或省略。新文件名保证不覆盖原结果。依赖与版本沿用 [[test/spectral-counting/gap-v1/README]]；运行时只读数学输入 JSON，不读取 Markdown 或 Git 元数据。

普通探针 `probe-01.json` 保留全部预算内检查：$L=1$ 时D/N整数不同；$L=2$ 时部分矩阵尾修正尚不能同号；$L=3,N=32,M=3$ 首次通过后停止探针并执行该唯一可靠配置。失败仅表示该配置未满足充分判据，未宣称真实导模不存在。没有通过调松符号阈值、扩大目标窗、改变切口或改变材料获取成功。
