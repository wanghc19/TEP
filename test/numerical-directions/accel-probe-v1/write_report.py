"""Write the authorized Chinese probe notes from completed scalar outputs.
Input: the three existing runs. Output: this experiment README and accel-probe.md.
"""
import json
from pathlib import Path
root=Path(__file__).resolve().parent
repo=root.parents[2]
load=lambda n,name='science/probe.json':json.loads((root/f'output/run-{n:03}'/name).read_text())
a,b=load(2),load(3)
s2,s3=load(2,'summary.json')['three_templates'],load(3,'summary.json')['three_templates']
mons=[load(n,'monitor.json') for n in [1,2,3]]
rows=[x for x in a['rows'] if x['template']=='center']+[x for x in b['rows'] if x['name']=='inverse_6' and x['template']=='center']
names={'baseline':'默认','tol_x10':'容差 ×10','tol_x100':'容差 ×100','tol_x1000':'容差 ×1000','tol_budget':'预算容差 ×57','sliver_1':'薄层初始 1 面板','combined_panels':'×1000＋1 面板','degree_10_budget':'预算容差＋次数 10','degree_8_budget':'预算容差＋次数 8','degree_6_budget':'预算容差＋次数 6','series_12_budget':'预算容差＋级数 12','series_8_budget':'预算容差＋级数 8','combined_all':'预算容差＋次数10/级数8/1面板','inverse_6':'×1000＋1面板＋逆迭代6'}
table='| 中心设置 | 秒（光滑／薄层） | 面板（光滑／薄层） | S 上界 / 1e-11 | 超额 / 1e-13；% |\n|---|---:|---:|---:|---:|\n'
for x in rows:
 table+=f"| {names[x['name']]} | {x['seconds']:.2f}（{x['smooth_seconds']:.2f}/{x['sliver_seconds']:.2f}） | {x['smooth_panels']}/{x['sliver_panels']} | {x['upper']/1e-11:.8f} | {x['excess']/1e-13:.6f}；{x['excess_percent']:.4f}% |\n"
best={x['template']:x for x in b['rows'] if x['name']=='inverse_6'}
three='| 最佳设置模板 | 旧秒数 → 新秒数（光滑／薄层） | 加速 | S 上界 | 超额 / % |\n|---|---:|---:|---:|---:|\n'
old={'left':160.52566095833333,'center':119.36791008333333,'right':181.412800625}
for name in ['left','center','right']:
 x=best[name];three+=f"| {name} | {old[name]:.2f} → {x['seconds']:.2f}（{x['smooth_seconds']:.2f}/{x['sliver_seconds']:.2f}） | {old[name]/x['seconds']:.2f}× | {x['upper']:.10e} | {x['excess']:.4e} / {x['excess_percent']:.4f}% |\n"
run_table='| 运行 | 内容／结果 | 实测墙钟 s | 峰值 RSS GiB | 启动前预计 s / GiB |\n|---|---|---:|---:|---|\n'
for n,desc,forecast in [(1,'基准及 profiler；时间启动保护保留部分结果','1100–1650 / 2.1–2.6'),(2,'无 profiler 的完整旋钮测试及三模板','1120–1500 / 2.1–2.6'),(3,'18次复现及唯一6次逆猜测探针','350–550 / 2.1–2.6')]:
 m=mons[n-1];run_table+=f"| run-{n:03} | {desc} | {m['wall_seconds']:.3f} | {m['peak_process_tree_rss_gib']:.3f} | {forecast} |\n"
commands='''```sh
python3 test/numerical-directions/accel-probe-v1/launch_probe.py --output test/numerical-directions/accel-probe-v1/output/run-001
python3 test/numerical-directions/accel-probe-v1/launch_probe.py --entry accel_sweep --output test/numerical-directions/accel-probe-v1/output/run-002
python3 test/numerical-directions/accel-probe-v1/launch_probe.py --entry accel_iterations --output test/numerical-directions/accel-probe-v1/output/run-003
```
'''
verdict='''**严格的“三模板分别至少 3 倍”判据未通过。** 最佳已测设置为容差 ×1000、乘积次数 12、级数 16、薄层初始 1 面板、逆猜测迭代 6 次；左／中／右加速 2.37／6.79／2.71 倍，S 超额分别 0.1995%／4.5678%／0.4416%。总界面时间从 461.388 降至 152.155 秒（3.03 倍）。结果处于有明显收益、逐模板尚未达标的区间，尚无全参数不可行结论。'''
validity='''所有表中行的 PM 运算测试、自映射、共同单射域、实际分支、最终余项断言及 Q16/Q24 包含检查均通过。完整中心默认上界 1.9323414727573126e-11 在 run-001、002 相对差均为 0；run-003 先用默认 18 次迭代精确复现 run-002 最快中心上界 2.0183554376854797e-11，相对差也为 0。最佳三模板最小自映射／实际分支裕量为 0.00599033／0.10160834。中心单面板有一条弧自动细分，实际薄层面板 321；左右为 320。'''
math='''默认每元素容差为 1e-13/(3×640)=5.208333333333334e-17；“预算容差”是 1.9e-12/640，即默认的 57 倍。除明确标出的参数外，默认次数 12、级数 16、薄层 4 面板、逆猜测 18 次。次数和级数单参数行以预算容差行为参照。乘积丢弃项、倒数和三角级数余项仍全部计入；细分深度与所有有效性检查未改。对降低次数，增加的余项触发更多细分，因而耗时反升；级数降阶仅略有收益。薄层 1 面板已试最少初始面板，未追加 2 面板的中间设置。'''
extra='''仅用原四类旋钮，最好设置是 ×1000＋1 面板：左／中／右 79.880／29.721／78.447 秒，合计 188.049 秒。profiling 指向固定 18 次逆猜测迭代后，只追加一次 6 次迭代。该循环只生成多项式猜测；末次缺陷 `||B(F(guess)-X)||/(1-kappa)`、猜测所在立方体和共同单射域检查独立给出误差，全部保留，因此减少猜测迭代未更改证书公式。默认仍为 18 次；`inverse_iteration_count.m` 只改变这一计算预算。中心上界变化 1.3964e-17，面板数未增加。此组后停止，无进一步优化。'''
profile='''正常中心基准 131.144 秒＝光滑 78.011＋薄层 53.133 秒（计时尾差不足 0.001 秒）；倒数级数包含子调用计时 7.098 秒，中心 sin/cos 调用为 0。基准 640 次光滑细分中，632 次为容差、8 次为收缩条件。run-001 带 profiler 的完整中心为 548.205 秒：逆模型与几何 468.537 秒（85.5%，其中固定 18 次迭代三行合计 284.565 秒）、PM 乘积 165.839 秒／4225752 次、解析矩积分 0.118 秒。后面几项嵌套于前项，不能相加。来源：run-001 的 `science/profile-functions.json`、run-002 的 `science/baseline-center.json`。'''
estimate=f'''固定其他成本，用旧 MATLAB 内部总计 698.135 秒扣除旧界面 461.388 秒、加新界面 {s3['interface_seconds']:.3f} 秒，得到 **{s3['estimated_pipeline_seconds']:.2f} 秒**；这是估计，未重跑整条可靠积分流水线。总 S 上界 {s3['upper']:.12e}，Q16 为 {s3['Q16']:.12e}，超额 {s3['excess']:.6e}（{s3['excess_percent']:.4f}%）。按 9.95 敏感度，S 单项相对 Q16 增宽 {s3['S_only_width_excess_vs_Q16']:.6e}（旧宽度的 0.2081%）；相对旧证书增加 0.1985%。'''
mass='''薄层循环同时给质量偏差界：减板后合计由 6.80236e-12 升至 8.33106e-11。若把新质量界一并代入同一四角公式，标量重组宽度为 4.554474131168718e-9，相对原记录 4.4623318373737675e-9 增加 2.0649%；所以整个区间的增宽应采用约 2.06%，而非只报 S 的约 0.20%。这项重组沿用已算出的 E、公共 S 和质量修正项，未另做全流程运行，舍入仍排除。'''
remaining='''仍需保留的全流程非界面部分约 236.75 秒；本次前置实测主要是精确通量转换及两阶积分清单 80.76 秒、通量求解和浮点检查 49.20 秒、v1 证书 42.56 秒。最佳引线仍各需 640 个光滑元素和 320 个薄层面板，并逐一处理 13 个胞元的场与通量。6 次迭代后左／右光滑部分仍为 44.81／43.95 秒，级数总计各仅约 4.38／4.35 秒；余下主要工作在每面板的模型及逐胞元 PM 运算。引线内部未另开 profiler，未精确分离这两项。'''
readme='''# 界面 S 证书加速探针

accel = acceleration（加速）；v1/v2 = 版本号；PM = polynomial model（含统一余项的多项式模型）；FEM = finite element method；DtN = Dirichlet-to-Neumann；RT = Raviart–Thomas；qj = Goerisch 量 q 和 J；RSS = resident set size；JSON = JavaScript Object Notation；CSV = comma-separated values；Q16/Q24 = 16/24 阶求积。I9 为旧实验编号；poly2 = 二元 polynomial（多项式）；stats = statistics（统计）；RT3 为三阶 Raviart–Thomas。

## 目的与结论

'''+verdict+'''

## 方法与计算边界

复制 qj-cert-v2 所需 MATLAB 文件到本目录，旧目录保持只读。每个进程从相同模型重建一次 P3 场、通量和 v1 证书，随后在内存中复用；没有每设置重新生成场，也没有保存大场缓存。轮次变化和新增 profiler/计时操作只在本目录。阶段计时由 `accel_probe.m`（带 profiler）、`accel_sweep.m`（干净计时进程）、`accel_iterations.m`（唯一追加迭代设置）输出。

'''+math+'\n\n'+extra+'''

## 启动计划、复现与资源

每个进程启动前均写过完整预估，见下表。全部串行，MATLAB R2023b，11 个计算/OpenMP线程、OMP_DYNAMIC=FALSE；启动器调用未修改的 diagnostics-v1/monitor.py，使用升级权限；30分钟软限、40分钟硬限、3 GiB 峰值硬限。脚本还在累计内部时间超过 1650 秒时禁止启动下一设置。

'''+commands+'\n'+run_table+f'''
总监控墙钟 {sum(x['wall_seconds'] for x in mons):.3f} 秒，最高峰值 {max(x['peak_process_tree_rss_gib'] for x in mons):.3f} GiB。本目录约 10.0 MB，工作树约 335 MB；保留全部运行与退出记录，没有大 MAT 输出。复现时使用未存在的新编号。

run-001 的 profiler 使中心从正常 135.759 秒增为 548.205 秒。关闭后，同样 1280 个薄层面板仍由约 55 秒变为约 184 秒，因此后续三条容差行只用于精度／面板核对，不参与加速比较。运行在 1719.663 秒因 `probe:TimeBudget` 启动保护退出，已完成行的检查全通过。run-002 未调用 profiler，默认中心恢复为 131.144 秒；run-003 同样不调用。run-001、002 的总时间超过最初预估，均在监控限内；run-001 的偏差主要来自 profiler 及其后续开销，run-002 的低次数设置因增加面板比预计更贵。

## 基准分项

'''+profile+'''

run-002 前置总计 218.175 秒：搜索 2.223，P3 场生成 31.135，准备 12.177，通量及浮点检查 49.197，精确通量转换与清单 80.759，v1 证书 42.563；其余 0.121 秒为标量复现、记录和控制开销。这些互不重叠。profiler 表的嵌套函数时间与这一分解分开使用。

## 中心扫参

来源：run-002/science/probe.json；最后一行来自 run-003/science/inverse_6-center.json。上界和超额均使用原 S 的量纲，超额参照同场 Q16。各行检查均通过。

'''+table+'''
## 三模板确认

比较分母是 qj-cert-v2/output/run-004/science/interface-certificate.json 的旧模板秒数；本次只重测了默认中心（131.144 秒，旧值 119.368 秒），左右默认值未重跑。中心相对本次基准的加速为 7.46 倍。以下为最终 6 次迭代设置，来源 run-003/science/inverse_6-*.json。

'''+three+'\n'+validity+'''

最佳三模板原始 Q16 为 left 7.227256881233850e-12、center 1.93019002106525e-11、right 8.405380999206935e-12（完整精度以各行 JSON 为准）。最低共同单射域等检查按原 assert 执行；未删除或放松有效性断言。

## 对整条流水线的含义

'''+estimate+'\n\n'+mass+'\n\n'+remaining+'''

## 输出与核查入口

- 每次运行的 `science/probe.json` 保存配置、前置分项、全部设置、余项、面板数、分支裕量、PM 测试和 Q16/Q24 包含结果；单行 JSON、逐弧 CSV 同时保留。
- `monitor.json`、`resource.csv`、`run.log` 是监控和运行记录；run-001/science/profile-functions.json 是函数、子调用和逐行 profiler 数据。
- `summarize_probe.py` 读取原始 JSON，写运行目录中的 sweep.csv 和 summary.json，计算加速比、S 单项敏感度以及包含新质量偏差的四角标量重组。它不启动 MATLAB。
- `write_report.py` 只从已有标量输出生成本 README 和指定研究笔记。四角 Python 算式已用旧证书输入复现原端点与宽度，差为 0；验证记录见 run-003/postprocessing-validation.json。

本阶段已经完成小探针；未覆盖舍入，也未取得三个模板各至少 3 倍的设置。没有把有限扫参解释为所有参数配置的不可能性证明。
'''
(root/'README.md').write_text(readme)
short="""# Stage 9a：界面 S 证书成本探针

**结论：已测设置未达到三模板各 ≥3×。** 最佳加速左／中／右为2.37／6.79／2.71倍，各模板S超额均<10%；总界面461.39→152.15秒（3.03倍）。属于有显著收益但逐模板未达标的中间结果，未证明所有参数配置不可行。

**基准。** 正常中心131.14秒（光滑78.01／薄层53.13），原上界1.9323414727573126e-11相对复现差0；倒数级数7.10秒，sin/cos调用0。640次细分中632次因容差、8次因收缩条件。独立profiler共548.20秒：逆模型/几何468.54秒（其中18次逆猜测迭代284.56），PM乘积165.84秒／423万次，矩积分0.118秒；这些嵌套时间不可相加。前置218.18秒包括场31.14、准备12.18、通量及检查49.20、精确通量/积分清单80.76、v1证书42.56、搜索2.22秒。

**中心扫参。** 默认容差τ₀=1e-13/(3×640)，预算容差=57τ₀；默认次数12、级数16、薄层4面板、逆猜测18次。次数/级数行仅相对预算容差行改变一个参数。所有行PM测试、自映射、单射域、分支、余项及Q16/Q24包含检查通过。

"""+table+"""
**三模板。** 原四类旋钮最好为×1000＋1面板，左/中/右79.88/29.72/78.45秒。归因后只追加逆猜测18→6；末次缺陷和所有域检查独立保留，证书公式未改。先以18次复现已有最快中心，上界相对差0；改6次后中心上界仅变化1.3964e-17。下表为最终设置；比值分母为qj-cert-v2/run-004旧时间，左右默认值未重跑。

"""+three+"""
**流水线。** 预计698.135−461.388＋152.155=**388.90秒**。总S上界3.586774161826e-11，超出Q16共9.332035e-13（2.6713%）；按9.95敏感度，S单项增宽9.2854e-12，约0.208%（相对旧证书0.199%）。减板也放宽质量偏差界：合计6.8024e-12→8.3311e-11。将新质量界一并作四角标量重组，宽度为4.554474e-9，较旧4.462332e-9增**2.065%**。这是现有证书的标量重组，未重跑完整流水线；舍入仍排除。

**剩余成本。** 固定非界面部分约236.75秒。最佳引线仍各有640光滑元素、320薄层面板，逐一处理13胞元；光滑仍需约44秒，倒数/三角级数合计仅约4.4秒。剩余工作集中于每面板模型和逐胞元PM运算，二者在引线内部未单独profiling。降次数触发更多面板，降级数仅略有收益；探针到此停止。

**复现/成本。** 仓库根执行（旧编号保留，复现换新号）；原monitor、11线程、升级权限。run-001为1719.663秒/2.001GiB（profiler后计时异常，预算保护退出）；run-002为1642.053秒/1.951GiB；run-003为419.873秒/1.968GiB。总监控3781.589秒，全部已完成数值检查通过。

```sh
probe_dir=test/numerical-directions/accel-probe-v1
python3 "$probe_dir/launch_probe.py" --output "$probe_dir/output/run-001"
python3 "$probe_dir/launch_probe.py" --entry accel_sweep --output "$probe_dir/output/run-002"
python3 "$probe_dir/launch_probe.py" --entry accel_iterations --output "$probe_dir/output/run-003"
```

来源：上述运行目录的science/probe.json、run-001/science/profile-functions.json、monitor.json；派生比值与四角数据见run-003/summary.json。参数、逐弧CSV、完整检查和预算记录见实验README。
"""
(repo/'research/explorations/numerical-directions/accel-probe.md').write_text(short)
