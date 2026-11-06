"""Write the resolution-study report from accepted scalar records.
Input: scalar results and output report paths. Output: Chinese comparison report.
"""
import argparse,json
from pathlib import Path
from decimal import Decimal,ROUND_CEILING
p=argparse.ArgumentParser();p.add_argument('--input',required=True);p.add_argument('--report',required=True);a=p.parse_args();rows=json.loads(Path(a.input).read_text());assert len(rows)==8;ref=rows[0];field=[r for r in rows if not r['settings']['field_source']];ev=[r for r in rows if r['settings']['field_source']]
def f(x):
 d=Decimal(str(x));q=Decimal(1).scaleb(d.adjusted()-7);return format(d.quantize(q,rounding=ROUND_CEILING),'.7E').replace('E','e')
def label(r):
 s=r['settings']
 if s['field_source']:return '面板×2' if s['panels']==2 else 'L=64' if s['chebyshev']==64 else '192 bit'
 return f"{s['center_nodes']}/{s['lead_nodes']}/{s['lead_nodes']}, M={s['rayleigh_M']}"
def table(rs):
 text='| 设置 / run | 中心材料 | 左材料 | 右材料 | 竖壁 | 接缝 | Q | 2R | 秒 / GiB |\n|---|---|---|---|---|---|---|---|---|\n'
 for r in rs:text+='| '+label(r)+' / '+r['run'][4:]+' | '+' | '.join(f(x)+'；'+f(y) for x,y in zip(r['eps'],r['weighted']))+' | '+f(r['Q'])+' | '+f(r['width'])+f" | {r['wall_seconds']:.3f} / {r['rss_gib']:.3f} |\n"
 return text
f48=sorted([r for r in field if r['settings']['rayleigh_M']==48],key=lambda r:r['settings']['center_nodes']);ec=[float(Decimal(r['Q'])/Decimal(ref['Q'])-1) for r in ev];fm=[float(Decimal(r['Q'])/Decimal(ref['Q'])-1) for r in field if r['settings']['rayleigh_M']!=48]
old=Path(a.report).read_text();facts=old[old.index('| 项目 | 已查事实与来源 |'):old.index('\n\n未找到多个h')]
text=f'''# 场分辨率与评价分辨率：resolution-v1

## 目的与结论
密度节点由256/128/128增至384/192/192、512/256/256，宽度由{f(f48[0]['width'])}降至{f(f48[1]['width'])}、{f(f48[2]['width'])}。同一512场改变评价设置，Q相对参考的最大变化为{100*max(abs(x) for x in ec):.7g}%；改变M至40/56的最大变化为{100*max(abs(x) for x in fm):.7g}%。这些已测行表明当前宽度主要跟随场的密度分辨率，评价误差只是小项。

以下是对应精确binary64导出场的可靠残差上界。每行重算质量和两组C证书；五个完整场行重算472项含舍入谱隙检验，三个同场行复用同一参考谱隙证书并重新检验新区间在其中。C依次为(2.490254,1.181583,1.233941,1.035553,1.035553)，全部行采用经当行圆盘证书确认的U=1.23587。各组单元格为 $\\epsilon_g$；$C_g\\epsilon_g$。宽度为 $\\mu$ 变量的 $2R$。表内正上界向上显示8位有效数，浮点参照同精度显示。原始标量、向外端点、各阶段成本及同场浮点参照见`test/bie-bound/resolution-v1/tables/reference-results.json`、`resolution.csv`；各run的`03-residuals/groups.json`、`06-enclosure/result.json`及`end-to-end.json`给出来源。

## 场分辨率

'''+table(sorted(field,key=lambda r:(r['settings']['rayleigh_M'],r['settings']['center_nodes'])))
text+='\n参考khat=1.558437894182088。上述各行的候选（相对参考ulp）依次为：'+ '；'.join(f"{label(r)}：{r['k']} ({r['k_ulp_from_reference']:+d})" for r in sorted(field,key=lambda r:(r['settings']['rayleigh_M'],r['settings']['center_nodes'])))+'。中心材料贡献主导粗场误差；候选的末位变化与残差宽度分开解释。\n\n## 固定场的评价分辨率\n\n'+table([ref]+ev)
text+='\n基准为中心192面板、每侧材料64面板、每壁16段、每接缝8段，固定实节点L=48，主精度128 bit。面板×2同时加倍所有目标分区；L=64将固定插值次数改为63，中心局部Taylor次数52及独立自适应自作用规则保持，合并时补零；192 bit提高主算术精度，原192 bit转换与更高精度独立控制保持。源分区、源矩阶数及解析余项公式不改。\n'
text+='\n同场浮点参照（有限状态残差多项式平方积分中点求和后开方，去掉模型误差加项）依次为：'+', '.join(f(x) for x in ref['floating_finite'])+'。无限尾另有可靠界，各组尾平方至多为有限部分的1e-6；此参照没有另一次双精度核求值的噪声。参考上界相对这些值的加宽依次为：'+', '.join(f'{100*x:.6g}%' for x in ref['evaluation_fraction'])+'。\n'
text+='\n各评价行直接读取run-001的同一fixed-input/coefficients文件，路径列在各自scientific-inputs.json。两份上界都适用于同一场，逐组可取较小者：'+', '.join(f(min(Decimal(r['eps'][j]) for r in [ref]+ev)) for j in range(5))+'；上界不必随这些参数单调，逐组较小者仍为同一场的有效上界。全部浮点参照及逐组相对变化另见CSV。\n\n## 成本—宽度与FEM事实\n\n| 配置 | 计时边界 | 秒 | 宽度2R |\n|---|---|---|---|\n'
for r in rows:text+=f"| {label(r)} | {'同场残差/质量/C/装配及审核' if r['settings']['field_source'] else '空目录至最终区间，含搜索与谱隙'} | {r['wall_seconds']:.3f} | {f(r['width'])} |\n"
text+='''| FEM原精度 | 历史P+Q+A+B+C+D阶段和 | 4009.012 | 4.4623318e-9 |
| FEM扣除B+C | 同上扣去(H)中B+C=3259.474秒 | 749.538 | 4.4623318e-9，仍以(H)为前提 |
| FEM参数化original/fast | 仅P+Q，完整进程 | 734.613 / 393.315 | 4.4623318e-9 / 4.5544741e-9，均以(H)为前提 |

run-001中残差/审核/质量/C装配阶段和为598.189秒（整次运行918.650秒）；这只是该进程内的阶段和，未另测标准设置的独立后处理冷启动。BIE同场行的参考场生成成本已包含在run-001，不能把其增量时间与FEM完整链作速度比。FEM67分钟是历史阶段和（含(H)，舍入排除），BIE是本次含舍入整链实测（不声称唯一性）；BIE还计入带隙分类，FEM该表从已有窗口开始。逐阶段BIE成本见本实验`tables/tables.md`。FEM来源与细节如下；表内`internal/`、`examples/`、`output/`均相对`test/fem-goerisch/pipeline-v1/`。

'''+facts
text+='''

未找到多个h网格上完整E/M/S与(H)链的FEM成本—宽度序列。`test/numerical-directions/goerisch-v3/README.md:19–22,67–88,102`有同g48上P2/P3与RT2/RT3的普通浮点结果；它们不是另一套h网格证书，故不填成可靠h收敛表。

## 核查与复现

run-001与pipeline-v1 run-002的候选位、五组残差、Q和宽度差均为0。数值相同，墙钟由旧827.120秒变为本次918.650秒，主要增加在搜索39.04秒和残差46.16秒；未单独测量负载因素。参数化副本13个代表目标相对差为0。八个成功行均通过目标覆盖/独立Gauss积分、全列与实际状态列对照、N+10尾检验、两组C证书、两精度及精确有理数装配；全部当次重算的谱隙检验通过。同场输入清单与候选位检查通过。

run-004在残差和质量核查通过后，十进制打印的缩放球跨过整数，unique_fmpz返回空值而停止（724.894秒，1.862 GiB）。修正只在缩放后再次提取安全方向端点；run-005小核查通过（1.309秒），run-006从空目录重算成功。run-009因监控目录扫描与输出压缩竞争而中止；其进程已终止，部分结果不采用，监控覆盖331.506秒、采样峰值2.493 GiB，异常后的全程峰值缺失。修复扫描并改为运行间归档，run-010重算成功。失败和开发核查成本单列，不混入配置成本。

复现：在实验README的公共绝对路径参数后调用`run_pipeline.py --output 新目录`重做参考；调用`varied/run_pipeline.py`并指定`--center-nodes N --lead-nodes n --rayleigh-M M`重做场行；同场行再传`--field-source 本实验参考run`及`--panels 2`、`--chebyshev 64`或`--precision 192`之一。各run的command.json记录完整命令。所有运行串行，MATLAB11线程、残差8进程，30/40分钟与3 GiB监控限额；没有新增FEM运行。
'''
Path(a.report).write_text(text);print('report characters',len(text))
