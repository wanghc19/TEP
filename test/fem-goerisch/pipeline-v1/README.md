# 参数驱动的 FEM–Goerisch 常规流水线 v1

## 目的与范围

从问题模型及给定搜索窗口，在一个 MATLAB 进程内只搜索一次，依次生成 P2 候选、P3 FEM–DtN 试探场、RT3 通量、E/M/S 积分证书、无 (H) 的 I₁ 和依赖 (H) 的四角区间。舍入仍排除。只支持 `example_ref` 及中心密度的正对比变化（rho_center > rho_background）；其他参数变化在网格生成前逐字段拒绝。没有运行 (H) 检查。

FEM、DtN、RT3、P2/P3、BIE 展开见上级 README；ref=reference，qj=Goerisch q 和 J，PM=polynomial model（含余项的多项式模型），poly2=二元多项式，RSS=resident set size，JSON=JavaScript Object Notation，CSV=comma-separated values，I9=历史实验编号。

## 入口与参数

- `examples/example_ref.m`：model（曲线、密度、引线、核心、端口、相位、胞元、截断及渐消），windows（k 搜索窗、mu 端点、局部括区），discretization（搜索网格、P3/RT3、求积和 PM），tolerances，resources。
- `run_pipeline(example,setting,output_dir)`：显式结构、`original` 或 `fast`、新输出目录。所有场、模板、通量在内存传递。
- `validate_example.m`：完整字段支持检查；只允许 model.rho_center 变化；当前正对比限制来自内外元素分类及带符号的质量偏差界。
- `reference_regression.m`：仅参数完全等于 example_ref 时比较历史根、q、E/M/S 和区间；一般参数路径不读取旧输出。
- `launch_pipeline.py`：显式例名、设置、目录及 MATLAB 路径；使用本目录复制的 `monitor.py`。监控仅增加可传入 MATLAB 路径及收紧目录限制，没有跨运行累计计时。
- `write_intervals.py`：只读新积分 JSON，计算高精度标量公式及朝外的十进制显示。它不覆盖上游浮点舍入。

复制来源：`test/numerical-directions/accel-probe-v1/` 中的 P/Q/F 帮助函数；其数学路径来自 fem-pipeline-v1、qj-cert-v2。没有复制实验驱动器的旧结果读取和回归断言。全元素自映射、共同单射域、实际分支、几何、余项、通量及相位检查保留。

## 运行前预估与复现

run-001 original：预计完整墙钟 720–1000 秒、峰值 2.0–2.6 GiB。run-002 fast：预计 390–600 秒、峰值 2.0–2.6 GiB。依据 qj-cert-v2 原全程约 698 秒及 accel-probe-v1 非界面约 237 秒、快速界面约 152 秒。均包含搜索、生成、通量、两阶检查、积分证书；每次独立 1800/2400 秒、3 GiB。11 个 MATLAB/OpenMP 线程，OMP_DYNAMIC=FALSE。不保存 MAT 场文件。

```sh
python3 test/fem-goerisch/pipeline-v1/launch_pipeline.py --example example_ref --setting original --output test/fem-goerisch/pipeline-v1/output/run-001 --matlab /Applications/MATLAB_R2023b.app/bin/matlab
python3 test/fem-goerisch/pipeline-v1/launch_pipeline.py --example example_ref --setting fast --output test/fem-goerisch/pipeline-v1/output/run-002 --matlab /Applications/MATLAB_R2023b.app/bin/matlab
```

原设置：元素容差 1e-13/(3×640)，4 薄层面板，18 次逆猜测迭代。快速设置：容差 ×1000，1 面板，6 次逆猜测迭代。两者 PM 总次数 12、级数 16，分支、细分上限和丢弃项余项规则相同。

## I₁ 与交付格式

取 a=1+E₋/M₊，b=1+E₊/M₋，d=b S₊/M₋。由 δ=q S/M−(q−s)²/s²≤d，安全外包为
`[a(1+d/2−sqrt(d+d²/4))−1, b(1+d/2+sqrt(d+d²/4))−1]`。
该公式与 `research/explorations/numerical-directions/paper-review-pro.md` 的已审查 E/M 矩形公式相同，使用 Proposition 5 的正／负端点单调性；无需 (H)。它保证区间遇到谱，若称为点谱还需排除本质谱。四角公式和十二个严格符号条件原样保留。

- `candidates.json`：完整 modes、候选索引、搜索窗及 SINGLE_CANDIDATE / NO_CANDIDATE / MULTIPLE_CANDIDATES；后两者正常停止。
- `trial-summary.json`：搜索起点、P3 根与历史、q、E/M 浮点值、通量、迹、两阶检查和分项时间。
- `integrals.json`：E/M 两端、S_upper、公共及界面 S、s、gamma、alpha、十二个符号值及包含检查。
- `interval.json`：I₁、四角端点／宽度、朝外打印端点、假设和舍入状态；(H) 状态为 `under (H), (H) checked only in floating point: not yet`。
- `summary.json`、`timing.json`、`monitor.json`、`resource.csv` 和日志：互不重叠阶段时间、启动退出余项、进程树峰值及失败记录。

## 固定表示与剩余字面量

本版本的公开可变科学参数只有中心密度；其他字段用于显式交付与匹配，不表示已支持任意改变。

| 保留表示 | 位置／原因 | 入口保护 |
|---|---|---|
| 单位胞元半宽 0.5、相邻模板位置 -1/0/1、整数胞元平移 | native/search 网格、壁面与局部坐标；整体推广会改变配对及索引 | d=L=1、核心与端口、胞元数必须等于参考 |
| gamma=1 的残差与四角恒等式中的 1 | `four_corners`、`interface_residual`、精确 RT 装配；此处保留已审查公式 | model.gamma 必须为 1 |
| P3 的 10 系数、RT3 的 24 系数／12 边矩，以及精确 RT3 基表 | `interface_fields`、`interface_quadrature`、`exact_rt3_basis`；代数表示依赖阶数 | P3/RT3 固定 |
| 多项式渐消级数 12/18，逆域立方体与扩张系数，光滑／薄层最大细分 3/4 | 原证书的余项和分支规则，逐字保留 | 本阶段不改这些证明规则；PM 12/16 和迭代预算由 struct 传入 |
| 内核求解、几何判别及代数自测的 1e-7…1e-14 阈值、面积边界采样 8192 | 原有有效性／浮点诊断阈值；不冒充全局可调容差 | 主要误差预算在 tolerances；未开放的内核阈值固定 |

所有曲线物理参数、面积、Fourier 系数与 C3 已集中于 `model.curves`；参考背景、引线密度、相位、搜索窗、谱端点、截断与渐消位置均显式保存。旧归一化、根、尾表和区间数值不参与一般参数路径。

## 后续接口

阶段 2b 可直接接收相同 struct、候选、试探场及积分报告，追加浮点 (H) 检查；当前输出明确未检查 (H)。阶段 2c 用一个函数返回 example_ref，再改 model.rho_center；无需另复制计算目录。零候选状态仅表示筛选器未交付候选，不是无谱判断。

## 实测结果

两设置全部通过，原设置端点最大绝对差和相对差均为 0。快速宽度相对旧标量重组差为 2.22e-16（容限 1e-6），端点差为 0。下表宽度使用未打印截短的普通浮点端点之差；朝外打印端点另列在 interval.json。

| 设置／运行 | E 区间 | M 区间 | S 上界 | 四角原始区间 | 宽度 |
|---|---|---|---:|---|---:|
| original / run-001 | [11.470912271614043, 11.470912271618044] | [4.7230110180143914, 4.7230110180281955] | 2.9475799376947328e-10 | [2.4287286691977914, 2.4287286736601232] | 4.4623318373737675e-09 |
| fast / run-002 | [11.470912271614043, 11.470912271618044] | [4.7230110179378828, 4.723011018104704] | 2.9564839129097165e-10 | [2.4287286691538483, 2.4287286737083225] | 4.5544741311687176e-09 |

历史对照：original 对照 qj-cert-v2/output/run-004/science/interface-certificate.json；fast 对照 accel-probe-v1/output/run-003/summary.json 的 scalar_reassembly_with_new_mass_bias。新文件均在本目录 output/run-NNN；`regression.json` 保存全部旧值和差，`integrals.json`、`interval.json` 保存新值。两设置 E/M/S 上界差全部为 0。

| 设置 | I₁ 朝外打印 | 四角区间朝外打印 | 监控墙钟 s | MATLAB 内部 s | 峰值 RSS GiB |
|---|---|---|---:|---:|---:|
| original | [2.4286785150, 2.4287788272] | [2.4287286691977, 2.4287286736602] | 734.613085 | 713.882802 | 2.304108 |
| fast | [2.4286784393, 2.4287789029] | [2.4287286691538, 2.4287286737084] | 393.315381 | 377.335978 | 2.310944 |

original 的 I₁ 与论文打印值完全一致；fast 也重新计算 I₁。完整监控时间之比 original/fast=1.8677，宽度增加 2.0649%。这里计入搜索、试探场生成、通量、两阶核查和全部积分证书；尚无 (H) 检查。省去旧 qj 驱动中不参与证书的 transport_float 对照诊断，两设置使用相同计算边界。

## 分项成本与检查

时间来自 summary.json 的 times；每项互不重叠，首次模型／模板构建均计入。通量求解中的细分时间还在 trial-summary.json.flux_timing；积分与界面分项分别在 common-certificates.json 和 interface-certificate.json。

| 阶段 | original 秒 | fast 秒 |
|---|---:|---:|
| 参数／PM 检查 | 0.241199 | 0.217316 |
| P2 全窗搜索 | 1.962286 | 1.813638 |
| P3 场生成（含根） | 28.445360 | 28.383349 |
| 场与拟合几何准备 | 12.050751 | 11.931261 |
| RT3 装配与求解 | 5.747037 | 5.799127 |
| 同通量泛函 | 8.103414 | 8.402923 |
| 高阶求积与归一化检查 | 33.705609 | 34.796964 |
| 精确 RT3 表示转换及核对 | 16.456290 | 16.877915 |
| 两阶分区积分清单 | 63.890363 | 64.265243 |
| E/M 与公共 S 证书 | 40.736068 | 40.462760 |
| 界面两阶参照积分 | 7.419868 | 7.455825 |
| 界面证书 | 495.051725 | 156.897231 |
| 控制及 JSON 输出余项 | 0.072832 | 0.032426 |
| MATLAB 内部总计 | 713.882802 | 377.335978 |
| 启动／退出／监控及末尾输出余项 | 20.730283 | 15.979403 |

两个内部阶段和与总计之差均为 0；外部余项按监控总计减 MATLAB 函数总计定义。Python 十进制打印约 0.002 秒另记于 timing.json，不在 MATLAB 监控墙钟内。两次 MATLAB 监控合计 1127.928466 秒。没有失败运行。

- 两设置搜索各一次，均交付 k=1.5584630910866906；P3 根为 1.5584378944018986。候选到 P3 的交接来自内存，参考数仅用于回归。
- 两设置 q 相对旧值差为 0；同通量 J 的两阶缩放差 4.4480e-6 < 0.01，q 相对变化 1.1102e-16；质量／能量相对变化 2.2204e-15 / 2.4425e-15。
- 拟合面积相对误差最大 8.5775e-16 < 1e-12；原生胞元／相位迹差为 0，外侧法向矩为 0。原生求解、通量迹、求解残差和 P3 值／梯度检查均通过，原始值见 trial-summary.json。
- 公共 E/M 的 Q24 包含、质量修正带积分包含、界面 Q16/Q24 包含及十二个严格符号全部通过；自映射、共同单射域、实际分支和丢弃项余项断言保留且通过。详见 delivery-checks.json、界面逐模板 JSON 和 common-certificates.json。
- 支持检查已测试 beta、左引线密度、d 的变化会拒绝，中心密度变化可通过参数检查；未运行另一个密度。零／多候选的物理案例也留给后续，本版本对应分支直接返回状态。
- 内核静态核查未发现旧输出路径、load/fileread/readtable/jsondecode、根目录发现或旧参考数，见 run-001/static-checks.json。已生成的输入／输出全部是小 JSON/CSV 与日志，没有场 MAT。

后处理中的“朝外”仅指显示端点，舍入误差仍按本阶段约定排除。四角结果以 (H) 为前提；本阶段不继承旧例的 (H) 已认证状态。
