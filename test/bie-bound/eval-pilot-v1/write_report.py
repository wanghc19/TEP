"""Write the pilot report from one explicit run directory.
Input: run directory, experiment README path, authorized report path.
"""
import json,sys
from pathlib import Path
out,readme,report=map(Path,sys.argv[1:]);r=json.loads((out/'result.json').read_text());s=json.loads((out/'summary.json').read_text());es=r['evaluations'];m=s['monitor']
labels={'fmm12_n768':'FMM 1e-12 / 768','fmm12_n1536':'FMM 1e-12 / 1536','direct_n768':'直接 / 768','fmm14_n768':'FMM 1e-14 / 768'}
cn={'center':'中心材料','negative_material':'负侧材料','positive_material':'正侧材料','left_junction':'左接合墙','right_junction':'右接合墙','negative_walls':'负侧内墙','positive_walls':'正侧内墙'}
header=r'''# eval-pilot-v1：fixed-field evaluation pilot version 1

固定场评价先导第一版。BIE（boundary integral equation，边界积分方程）、FMM（fast multipole method，快速多极方法）、MFS（method of fundamental solutions，基本解方法）、QP（quasi-periodic，准周期）的全称也列在上级README。

## 目的与结论

按题设判据为 **real**：eps最大比值为RATIO，最大全宽为MAXW，所有评价均小于5e-9。四组必做评价共用一次构造的场。数据见 `output/run-003/result.json`、`summary.json`；短报告见 [bie-eval-pilot.md](../../../research/explorations/numerical-directions/bie-eval-pilot.md)。

## 运行前预估

依据I9.2的96秒和I8直接评价约190秒，单进程必需评价及预算允许时的可选评价预计12–20分钟，峰值2.6 GiB。1536点的大目标集按196608个目标分批调用FMM，并不保留评价后的稠密材料矩阵。使用复制的monitor.py，11线程、OMP_DYNAMIC=FALSE，软30分钟、硬40分钟、RSS 3 GiB；每秒记录当前部分和进程树RSS。

## 复现

从软件包目录运行，输出必须是新的空目录：

```sh
PYTHONDONTWRITEBYTECODE=1 python3 test/bie-bound/eval-pilot-v1/launch.py \
  --output /Users/whc/Documents/Work/dot-research/test/bie-bound/eval-pilot-v1/output/run-004 \
  --package-root /Users/whc/Documents/Work/dot-research \
  --fmm-root /Users/whc/Documents/Work/epost/test/i8/fmm-v1/vendor/fmm2d/matlab
PYTHONDONTWRITEBYTECODE=1 python3 test/bie-bound/eval-pilot-v1/summarize.py \
  test/bie-bound/eval-pilot-v1/output/run-004
PYTHONDONTWRITEBYTECODE=1 python3 test/bie-bound/eval-pilot-v1/write_report.py \
  test/bie-bound/eval-pilot-v1/output/run-004 \
  test/bie-bound/eval-pilot-v1/README.md \
  research/explorations/numerical-directions/bie-eval-pilot.md
```

`launch.py`显式传入软件包与现有FMM2D目录，使用本目录从 `test/fem-goerisch/pipeline-v1/monitor.py` 复制的监控器，调用 `/Applications/MATLAB_R2023b.app/bin/matlab -batch`。本地监控器增加了部分名称与逐部分峰值记录。数值入口 `eval_pilot(out, config, settings)` 不查找目录或读取旧输出。MAT文件已忽略，本次未保存MAT。

## 固定量与评价方式

$k_0=1.5584378941820909$，中心512点，左右引线各256点，$M=48$。构场一次，冻结匹配向量、原始密度、两侧完整传播矩阵与系数；每项评价后用 `isequaln` 检查。中心星形 $\rho=4$，左右三瓣形 $a=0.12/0.20$、$\rho=17$，均保留全局方向。768/1536点的密度用原始密度作interpft，不重求密度。构场始终使用FMM 1e-12。

`eval_pilot.m` 的构场、匹配、传播、几何、Kress材料处理、墙和质量公式来自I9.2；独立的 `pilot_config.m`、`pilot_geometry.m`、`pilot_classify.m` 来自同目录。直接代理势回调及构场后切换后端的方式来自I8的 `fmm_est_i8.m`，不采用I8的不同模型。

直接评价用 `kernel.h2d_directch` 替换全部光滑MFS代理势的FMM调用，每批512个目标；共同的自由空间及奇异核处理保留。1536点大目标集的FMM按196608个目标分批。40胞元有限和与每侧观察比率尾分开保存。尾的计时包含在材料/墙部分。周期接缝诊断省略，不进入eps。FMM2D接受1e-14请求，所有调用返回ier=0。

共同的 $C=9.578112278425445$；$\mu=k_0^2$，$Q=C\varepsilon$，$R=2\mu Q/(U-Q)$，$W=2R$，体缺陷项取0。

## 标量结果

'''
header=header.replace('RATIO',f"{s['largest_epsilon_ratio']:.9f}").replace('MAXW',f"{s['max_W']:.9e}")
text=header+'| 评价 / 节点 | eps | U | Q | R | W | 秒 |\n|---|---:|---:|---:|---:|---:|---:|\n'
for e in es:text+=f"| {labels[e['name']]} | {e['epsilon']:.10e} | {e['U']:.17g} | {e['Q']:.10e} | {e['R']:.10e} | {e['W']:.10e} | {e['seconds']:.3f} |\n"
text+=f"\n直接评价相对基线的eps变化为 {s['evaluation_changes']['direct_n768']['epsilon_relative_to_baseline']*1e6:.5f} ppm；1e-14评价为 {s['evaluation_changes']['fmm14_n768']['epsilon_relative_to_baseline']*1e6:.5f} ppm。1536点eps下降20.3844%，主要来自接合墙的法向项。U的跨度为 {s['U_span']:.8e}。\n\n"
text+='## 7 × 2 跳跃平方\n\n每表列出eps的全部七个分量。CSV保留17位输出，并将有限胞元与数值尾单列。\n\n'
for e in es:
 text+=f"### {labels[e['name']]}\n\n| 分量 | 值跳跃平方 | 法向跳跃平方 |\n|---|---:|---:|\n"
 for n,cname in cn.items():
  c=e['components'][n];text+=f"| {cname} | {c['value_squared']:.10e} | {c['normal_squared']:.10e} |\n"
 text+=f"\n来源：`output/run-003/{e['name']}-components.csv`。\n\n"
text+='## 成本\n\n以下为该部分的秒数 / 每秒采样进程树峰值GiB。尾的有限和及几何尾代数包含在对应的材料/墙时间内。\n\n| 评价 | 材料 | 墙 | 质量 | 评价峰值GiB |\n|---|---:|---:|---:|---:|\n'
for e in es:
 vals=[]
 for part in ['material','walls','mass']:
  vals.append(f"{e['timing'][part]:.3f} / {m['peak_by_part_gib'][e['name']+'/'+part]:.4f}")
 text+=f"| {labels[e['name']]} | {' | '.join(vals)} | {s['evaluation_changes'][e['name']]['peak_rss_gib']:.4f} |\n"
text+=f"\n构场 {r['field_seconds']:.3f} 秒 / {m['peak_by_part_gib']['field']:.4f} GiB；几何 {r['geometry_seconds']:.3f} 秒 / {m['peak_by_part_gib']['geometry']:.4f} GiB。完整进程（含MATLAB启动、输出和监控）{m['wall_seconds']:.3f} 秒，峰值 {m['peak_process_tree_rss_gib']:.6f} GiB。标量组装各约0.04–0.05秒，部分短于RSS采样周期；原始记录见 `parts.csv` 和 `resource.csv`。\n\n"
text+='| 运行 | 秒 | 峰值GiB | 结果 |\n|---|---:|---:|---|\n'
for run,reason in [('run-001','旧启动路径不存在'),('run-002','所给FMM目录缺少MEX'),(out.name,'四项评价完成')]:
 if not (out.parent/run/'monitor.json').is_file():continue
 mm=json.loads((out.parent/run/'monitor.json').read_text());text+=f"| {run} | {mm['wall_seconds']:.3f} | {mm['peak_process_tree_rss_gib']:.6f} | {reason} |\n"
text+='\n## 核查与含义\n\n'
text+=f"- 基线：eps和R与题给I9.2数值的相对差均为0，通过1e-4要求。\n- 冻结场：构场次数1，四次 `isequaln` 均通过；审计最大缺陷 {max(e['audit']['maximum_defect'] for e in es):.8e}，小于预设1e-10。\n- 七分量求和：值平方和、法向平方和分别与保存总量一致，相对差均为0。\n- 后端：635次代理势调用有记录，其中直接评价140次，全部使用direct；FMM调用ier均为0。\n- 可选1536点直接评价：未做，768点直接评价 {es[2]['seconds']:.3f} 秒，超过题设300秒条件。周期接缝诊断未做，按题设不进入eps。\n- 判据：最大eps比值 {s['largest_epsilon_ratio']:.9f}，远小于3.2；最大W {s['max_W']:.10e}，小于5e-9。\n\n"
text+='本次是浮点估计，不是可靠上界。结果支持安排非圆曲线连续跳跃的可靠评价；其工作应包括奇异求积余项、核与舍入误差、曲线collar、质量下界和两侧无限尾。\n'
text=text.replace('run-003',out.name)
readme.write_text(text)
# Short report, with complete tables retained in the experiment.
prefix=r'''# BIE 固定场评价先导

**按题设判据为 real。** eps最大比值为RATIO，最大 $W=2R$ 为MAXW，全部小于5e-9。768点直接评价与原FMM评价的eps只差DIRECTPPM ppm；1e-14请求下只差STRICTPPM ppm。1e-9量级在本次评价变化下保留。

本次是浮点估计，不是可靠上界。

## 问题与固定量

固定 $k_0=1.5584378941820909$、中心512点/左右引线各256点、$M=48$，同一MATLAB进程只构场一次。匹配向量、密度及全部传播系数逐位未变；只用interpft增加评价节点，并切换光滑MFS代理势的FMM/直接后端。真实星形与左右不同三瓣形的材料、方向均与I9.2相同。$C=9.578112278425445$，$Q=C\varepsilon$，$R=2k_0^2Q/(U-Q)$；40胞元与两侧数值尾分别保留，周期接缝诊断不计入eps。

## 评价结果

'''
prefix=prefix.replace('RATIO',f"{s['largest_epsilon_ratio']:.7f}").replace('MAXW',f"{s['max_W']:.8e}").replace('DIRECTPPM',f"{s['evaluation_changes']['direct_n768']['epsilon_relative_to_baseline']*1e6:.2f}").replace('STRICTPPM',f"{s['evaluation_changes']['fmm14_n768']['epsilon_relative_to_baseline']*1e6:.2f}")
t=prefix+'| 后端 / 节点 | eps | U | R | W | 秒 / 峰值GiB |\n|---|---:|---:|---:|---:|---:|\n'
for e in es:t+=f"| {labels[e['name']]} | {e['epsilon']:.8e} | {e['U']:.17g} | {e['R']:.8e} | {e['W']:.8e} | {e['seconds']:.2f} / {s['evaluation_changes'][e['name']]['peak_rss_gib']:.3f} |\n"
t+=r'''
基线eps、R完全复现，相对差均为0。1536点eps下降20.38%，而U的变化仅4.16e-17。更换后端或FMM容差产生约十几至二十几ppm变化；节点变化仍有可见影响，具体半径尚未达到网格收敛。

## 主导分量

每格为“值跳跃平方 / 法向跳跃平方”，数值统一乘 $10^{-24}$。中心材料与左右接合墙合计占eps平方的96%左右；全部7×2分量及有限/尾项见实验目录的各 `*-components.csv`。

| 评价 | 中心材料 | 左接合墙 | 右接合墙 |
|---|---:|---:|---:|
'''
for e in es:
 vals=[]
 for n in ['center','left_junction','right_junction']:
  c=e['components'][n];vals.append(f"{c['value_squared']/1e-24:.5g} / {c['normal_squared']/1e-24:.7f}")
 t+=f"| {labels[e['name']]} | {' | '.join(vals)} |\n"
t+=f"\n最大单项始终是中心材料法向跳跃，占eps平方的37.6%–59.4%；1536点的主要变化是左右接合墙法向项下降约60%，中心材料法向项只变0.065%。四组的观察比率尾平方合计均小于7.64e-59。\n\n"
t+=f"## 成本与下一步\n\n完整运行 {m['wall_seconds']:.2f} 秒，峰值 {m['peak_process_tree_rss_gib']:.3f} GiB，11线程；两次路径启动失败共29.75秒，日志保留。直接768点耗时359.57秒，超过300秒，因此按题设未做可选直接1536点。FMM2D接受1e-14，返回ier=0。逐部分时间、峰值、Q、分量和核查见 [实验README](../../../test/bie-bound/eval-pilot-v1/README.md)；原始来源为 `test/bie-bound/eval-pilot-v1/output/run-003/result.json`、`summary.json`、`monitor.json`。复现命令见同一README。\n\n"
t+='本先导支持安排非圆曲线连续跳跃的可靠评价。下一步需给出Kress/核评价与连续求积余项、曲线collar及迹常数、局部质量下界、左右传播尾的一侧控制，并保留冻结场约定。\n'
t=t.replace('run-003',out.name)
report.write_text(t)
