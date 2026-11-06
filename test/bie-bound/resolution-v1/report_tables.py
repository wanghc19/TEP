"""Create resolution-study comparison tables from accepted scalar outputs.
Input: explicit scalar reference-results JSON and destination directory.
Output: Markdown tables, and same-field improvement checks; no scientific run.
"""
import argparse,json
from pathlib import Path
from decimal import Decimal,ROUND_CEILING
p=argparse.ArgumentParser();p.add_argument('--input',required=True);p.add_argument('--output',required=True);a=p.parse_args();rows=json.loads(Path(a.input).read_text());out=Path(a.output);out.mkdir(exist_ok=True);ref=rows[0]
def f(x):
 d=Decimal(str(x));q=Decimal(1).scaleb(d.adjusted()-7);return format(d.quantize(q,rounding=ROUND_CEILING),'.7E').replace('E','e')
def label(r):
 s=r['settings']
 if s['field_source']:
  return '面板×2' if s['panels']==2 else 'L=64' if s['chebyshev']==64 else '192 bit'
 return str(s['center_nodes'])+'/'+str(s['lead_nodes'])+'/'+str(s['lead_nodes'])+', M='+str(s['rayleigh_M'])
def table(rs):
 s='| 设置 / run | 中心材料 | 左材料 | 右材料 | 竖壁 | 接缝 | Q | 2R | 秒 / GiB |\n|---|---|---|---|---|---|---|---|---|\n'
 for r in rs:
  s+='| '+label(r)+' / '+r['run'][4:]+' | '+' | '.join(f(e)+'；'+f(v) for e,v in zip(r['eps'],r['weighted']))+' | '+f(r['Q'])+' | '+f(r['width'])+f" | {r['wall_seconds']:.3f} / {r['rss_gib']:.3f} |\n"
 return s
field=[r for r in rows if not r['settings']['field_source']];evaluation=[r for r in rows if r['settings']['field_source']]
text='## 场分辨率\n\n'+table(sorted(field,key=lambda r:(r['settings']['rayleigh_M'],r['settings']['center_nodes'])))
text+='\n所有行使用可靠质量下界 U=1.23587；各行重算的圆盘下界原始球见 JSON 的 mass_certificate。每格先列 $\\epsilon_g$，再列 $C_g\\epsilon_g$。\n\n| 设置 | khat | 与参考相差 ulp | 重算的圆盘下界（显示中点） |\n|---|---|---|---|\n'
for r in field:text+=f"| {label(r)} | {r['k']} | {r['k_ulp_from_reference']:+d} | {r['mass_certificate'].split(' +/-')[0].strip('[')} |\n"
text+='\n## 固定场的评价分辨率\n\n'+table([ref]+evaluation)
text+='\n同场普通浮点参照：从有限状态残差多项式的平方积分中点求和再开方，去掉模型误差加项；无限尾项另列可靠界。它不是另一次双精度核求值，因而不混入不同核算法的舍入噪声。\n\n| 组 | 参考可靠上界 | 同场有限部分浮点估计 | 参考相对加宽 | 所有已测设置中较小可靠上界 |\n|---|---|---|---|---|\n'
checks=[]
for j,name in enumerate(['中心材料','左材料','右材料','竖壁','水平接缝']):
 best=min([ref]+evaluation,key=lambda r:Decimal(r['eps'][j]));text+=f"| {name} | {f(ref['eps'][j])} | {f(ref['floating_finite'][j])} | {100*ref['evaluation_fraction'][j]:.7g}% | {f(best['eps'][j])} ({label(best)}) |\n"
for r in evaluation:
 assert r['k_hex']==ref['k_hex']
 checks.append(dict(run=r['run'],same_k_bits=True,Q_relative=float(Decimal(r['Q'])/Decimal(ref['Q'])-1),width_relative=float(Decimal(r['width'])/Decimal(ref['width'])-1),finite_midpoint_relative=[x/y-1 for x,y in zip(r['floating_finite'],ref['floating_finite'])],upper_relative=[float(Decimal(x)/Decimal(y)-1) for x,y in zip(r['eps'],ref['eps'])]))
text+='\n## 成本—宽度\n\n| 设置 | 完整场链 / 固定场后处理 | 秒 | 宽度 2R |\n|---|---|---|---|\n'
for r in rows:text+=f"| {label(r)} | {'固定场后处理' if r['settings']['field_source'] else '完整场链'} | {r['wall_seconds']:.3f} | {f(r['width'])} |\n"
text+='\n| run | 搜索 | 场重建/B拟合 | 可靠残差 | 残差审核 | 质量 | C及装配 | 谱隙 | 启动/编排余项 |\n|---|---|---|---|---|---|---|---|---|\n'
for r in rows:
 ds={z['stage']:z['seconds'] for z in r['stages']};rest=r['wall_seconds']-sum(ds.values());text+='| '+r['run']+' | '+' | '.join(f"{ds.get(k,0):.3f}" for k in ['01-search','02-field','03-residuals','04-residual-audit','05-mass','06-enclosure','07-band'])+f' | {rest:.3f} |\n'
(out/'tables.md').write_text(text);(out/'evaluation-checks.json').write_text(json.dumps(checks,indent=2));print('table rows',len(rows))
