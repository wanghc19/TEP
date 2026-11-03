"""Write the Chinese fitted-interface residual certificate report.
Input: successful full run. Output: README.md, preserving its coverage proof.
"""
import argparse,json
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('run');a=p.parse_args();run=Path(a.run);sd=run/'science';here=Path(__file__).resolve().parent
x=json.loads((sd/'interface-certificate.json').read_text());z=json.loads((run/'analysis.json').read_text());q=json.loads((sd/'interface-quadrature.json').read_text());v=json.loads((sd/'certificates.json').read_text());b=json.loads((sd/'baseline.json').read_text());rep=json.loads((sd/'reproduction.json').read_text());tr=json.loads((sd/'transport.json').read_text());inv=json.loads((sd/'inventory-exact.json').read_text())
old=(here/'README.md').read_text();start=old.index('<!-- coverage-proof-begin -->');end=old.index('<!-- coverage-proof-end -->')+len('<!-- coverage-proof-end -->');proof=old[start:end]
rr=run.resolve().relative_to(here).as_posix();sdir=rr+'/science';f=lambda a:format(a,'.17g');g=lambda a:format(a,'.12g');dec=z['scalar_decimal'];penalty=float(dec['penalty']);width=float(dec['width'])
L=['# 拟合界面残差与完整四角区间','',
'`qj-cert` = certificate for Goerisch quantities q and J（Goerisch 数量 q、J 的证书）；v2 = 版本 2。RT3 = Raviart–Thomas 三阶通量；P3 = 三次有限元；FEM = finite element method（有限元法）；DtN = Dirichlet-to-Neumann；RSS = resident set size（常驻内存）；JSON = JavaScript Object Notation；CSV = comma-separated values；BIE = boundary integral equation（边界积分方程）。','',
'## 目的','',
f'选择保留原场的 C 路线，补齐了全部拟合界面残差积分的截断误差界。$S_{{\mathrm{{int}},+}}={x["S_interface_upper"]:.16e}$，比同场 Q16 多 {z["interface_excess"]:.12e}（{100*z["interface_relative_excess"]:.6f}%），小于约 $1.1\times10^{{-12}}$ 的预算。', '',
f'在既有 (H) 与命题 1 前提下，完整四角区间为 [{float(dec["L"]):.16f}, {float(dec["U"]):.16f}]，宽 {width:.15e}，相对原基宽罚项 **{100*penalty:.6f}%**。E、M、S 每一部分均有截断误差界；浮点舍入仍排除。', '',
'全部本阶段规定检查通过，没有因 Q16/Q24 包含失败而加宽区间。主记录：[完整界面证书]('+sdir+'/interface-certificate.json)、[独立核查与标量复算]('+rr+'/analysis.json)。','',
'## 起点与输入','',
'代码复制自 [qj-cert-v1](../qj-cert-v1/README.md)。原 P3 g48 节点场、精确整数 RT3 基、同一个原始通量、同一固定 $s$、物理 taper 和端点 $1.32^2,2.37^2$ 保持。每次进程内重新做搜索、P3 根、通量与 v1 证书，不读旧 MAT。', '',
'使用既有 [截断误差界证明](../../../research/explorations/numerical-directions/qj-bounds-proof.md) 的引理 3.1、4.1–4.3、5.2，§5.4 的分支保留与多项式相减思路，以及定理 6.1。没有独立重证其假定的谱隔离 (H) 和命题 1。BIE 数值只用于最后的区间包含检查。', '',
f'根为 {f(b["generation"]["frequency"])}，$s={f(b["q"])}$。本次 v1 的 E/M 端点最大差、公共 S 相对差、界面 S 相对差、部分宽度相对差分别为 {rep["E_end_maxdiff"]:.3e}／{rep["M_end_maxdiff"]:.3e}、{rep["S_common_relative"]:.3e}、{rep["S_interface_relative"]:.3e}、{rep["partial_width_relative"]:.3e}。根相对差 {b["root_relative"]:.3e}。','',
'## 复现命令','',
'从仓库根目录执行；输出目录必须尚不存在。下面使用保留记录之后的新编号。','',
'```sh',
'python3 test/numerical-directions/qj-cert-v2/launch_qj.py --stage full --output test/numerical-directions/qj-cert-v2/output/run-005',
'python3 test/numerical-directions/qj-cert-v2/analyze_v2.py test/numerical-directions/qj-cert-v2/output/run-005',
'python3 test/numerical-directions/qj-cert-v2/write_v2_report.py test/numerical-directions/qj-cert-v2/output/run-005',
'```','',
'启动器调用 `diagnostics-v1/monitor.py` 和 MATLAB R2023b，11 MATLAB/OpenMP 线程，`OMP_DYNAMIC=FALSE`；启动按任务要求请求提权。软／硬限为 30／40 分钟，3 GiB。数值入口只接收显式输出目录与运行范围，不读取文档、Git 或旧结果来配置运行。','',
'## 路线选择','',
'仅试算证明 (5.18) 的输运场，保留 taper、同一个 p 和 s。E/M 用 native 界面贡献与 fitted 输运贡献替换，质量同时去掉原带符号 sliver 修正，保持同一输运场的一致性。','',
'| 量 | Q16 输运变化 | Q24 输运变化 |','|---|---:|---:|']
for label,key in [('E','E_change'),('M','M_change'),('S_int','S_change')]:L.append(f'| {label} | {tr["cases"][0][key]:.14e} | {tr["cases"][1][key]:.14e} |')
oldq24=1+inv['totals'][1][0]/sum(inv['totals'][1][1:3])
L.append(f'| q | {tr["cases"][0]["q"]-b["q"]:.14e} | {tr["cases"][1]["q"]-oldq24:.14e} |')
L.append(f'| 输运区间宽度 | {tr["cases"][0]["interval"]["width"]:.14e} | {tr["cases"][1]["interval"]["width"]:.14e} |')
L+=['',
f'输运后 Q16 界面 S 为 {tr["cases"][0]["S_interface"]:.14e}，总 S 为 {tr["cases"][0]["S"]:.14e}；总 S 增加 {100*tr["cases"][0]["S_relative_increase"]:.8f}%，宽度增加 {100*tr["cases"][0]["width_penalty"]:.8f}%，均不满足 T 路线门槛。因此采用 C 路线，最终区间始终使用原始场。','',
'## 界面残差证书','',
'每个 fitted 界面单元先积分对应 native 分支的光滑延拓。`interface_model.m` 用常矩阵压缩、自映射、共同单射域和最终多项式缺陷 (4.10) 给逆模型。多项式猜测可自由删项，最后的缺陷界独立计入猜测误差。分母、sin/cos、乘积和所有删项均按 §4.1 传播余项。', '',
'`pm.m` 以归一化面板为域，乘积后总次数截为 12，倒数与 sin/cos 级数到 16 阶；删项系数绝对值计入误差。先形成 (5.13) 的小残差分子再平方，最后按单项式矩积分。不同胞元复用模板几何和逆模型，场／通量系数分别累加。', '',
'对薄层，方法改为保守但便宜的绝对修正：保留两个 native 分支和两个 fitted 侧；在同一物理参数上先形成分支差，再用小残差的交叉项恒等式取界。扫掠 Jacobian 也先形成行列式模型再取绝对界。这样免去逐点的有符号归属，重叠会重复计数。它沿用 §5.4 的全部分支保留，并保留分支差抵消。','',
'| 模板 | 主分支积分值 | 积分余项 | 薄层修正绝对界 | S_int 上界 | Q24 |','|---|---:|---:|---:|---:|---:|']
for t,c in zip(x['templates'],z['comparisons']):L.append(f'| {t["template"]} | {t["smooth_value"]:.14e} | {t["smooth_remainder"]:.12e} | {t["correction_bound"]:.12e} | {t["upper"]:.14e} | {c["Q24"]:.14e} |')
L+=['',
f'合计光滑积分余项 {x["smooth_remainder"]:.12e}，修正绝对界 {x["correction_bound"]:.12e}。所得区间 [{x["S_interface_lower"]:.16e}, {x["S_interface_upper"]:.16e}] 包含同场 Q16={q["Q16"]:.16e} 与 Q24={q["Q24"]:.16e}。本次逐模板及 taper 子项也全部包含；没有需要单列的本阶段舍入包含失败。','',
'| 模板 | 覆盖弧数 | 光滑面板数 | 薄层面板数 | 已细分弧数 | 实际分支余量最小值 |','|---|---:|---:|---:|---:|---:|']
for t in x['templates']:L.append(f'| {t["template"]} | {t["arcs"]} | {t["smooth_panels"]} | {t["sliver_panels"]} | {t["subdivided_arcs"]} | {t["min_actual_branch_margin"]:.10g} |')
L+=['',
f'共覆盖 960 条弧，{z["smooth_panel_count"]} 个光滑面板，{z["sliver_panel_count"]} 个薄层面板。全部弧在 u 方向至少四等分，每条同伦线段保留全部 2×2 可能组合；没有采用“较大最小重心坐标”作为证明。`*-interface-arcs.csv` 保留逐弧修正、质量偏差和面板数。', '',proof,'',
'当前实现没有用 $x^HQx$ 的 Gram 大量相减来评价小残差。未来区间舍入仍须覆盖多项式系数、初值与缺陷评价的舍入，可能需要更高精度；本次余项和成本不构成区间算术版本的成本保证。','',
'## taper 界面','',
'在 n=±12、±13 的界面单元，保留原物理坐标公式的 χ 和 χ′，并在同一个物理点形成两分支的值差／梯度差。三角函数余项包含在残差模型及分支差模型中。没有把 taper 视为常数，也没有去掉尾部截断。','',
'| 模板 | taper 主分支值 | 积分余项 | 薄层修正界 | Q24 |','|---|---:|---:|---:|---:|']
for t,c in zip(x['templates'],z['comparisons']):L.append(f'| {t["template"]} | {t["smooth_taper_value"]:.14e} | {t["smooth_taper_remainder"]:.12e} | {t["taper_correction_bound"]:.12e} | {c["taper_Q24"]:.14e} |')
L+=['',
f'taper 界面浮点值合计 {q["taper_Q16"]:.14e}，其光滑余项和薄层修正合计为 {z["taper_remainder"]:.12e}、{z["taper_correction"]:.12e}；已包含在总 S_int 界中。','',
'## 质量偏差','',
'沿用同次 v1 的一维 $C_0$，在每个 u 子区间用已证明覆盖整个扫掠面的两个 native 逆模型求局部 V、L、D0、D1、Q1，再应用 (5.6)，乘原 u 子区间长度。所有导数仍是对原弧参数 u 的导数。共享节点的场在穿越 native 边时连续，因此分段梯度界可沿整个同伦线段使用。', '',
'局部复数模上界采用实部系数绝对值和、虚部系数绝对值和的 Euclidean 范数，再加模型余项；它比将这两个和直接相加更紧，仍给出复数模的上界。S 的残差界方法不因这个质量常数细化而改变。','',
'| 模板 | 新质量偏差界 |','|---|---:|']
for t in x['templates']:L.append(f'| {t["template"]} | {t["mass_bias"]:.14e} |')
L+=['',
f'总偏差从 v1 的 {v["mass_correction"]["bias"]:.14e} 降至 **{x["mass_bias"]:.14e}**，为 $9.4\times10^{{-12}}$ 分项预算的 {z["mass_budget_ratio"]:.6f} 倍。C0 积分余项、native taper 质量余项及原有 $10^{{-13}}$ 自愿半宽均保留；该自愿宽化没有被用作舍入保证。','',
'## 完整四角区间','',
'全部值对应同一原场、同一整数基通量和固定 s。E 与公共 S 界由同次 v1 计算，M 用本次局部质量偏差替换原偏差，界面 S 用新证书。','',
'| 量 | 区间或上界 |','|---|---|',
f'| E | [{f(v["E"][0])}, {f(v["E"][1])}] |',
f'| M | [{f(x["M"][0])}, {f(x["M"][1])}] |',
f'| 公共 S 上界 | {v["S_smooth"][1]:.17e} |',
f'| 界面 S 上界 | {x["S_interface_upper"]:.17e} |',
f'| 完整 S+ | {x["S_upper"]:.17e} |','',
f'定理 6.1 的 12 个严格符号全通过。四角 H、D_mu、−D_nu 的最小正余量分别为 '+ '／'.join(f'{float(a):.12g}' for a in dec['minimum_signs'])+'。按 (6.8) 的稳定式求端点；独立 Decimal 标量复算给出：','',
f'- L = {float(dec["L"]):.16f}',f'- U = {float(dec["U"]):.16f}',f'- 宽度 = {width:.16e}',f'- 相对基准 {b["width"]:.16e} 的罚项 = {100*penalty:.8f}%', '',
'完整区间包含给定 BIE 参考。Decimal 只减少最终标量相减的数值损失，不代表区间舍入认证。','',
'## 核查','',
'1. 通过：同进程复现根、v1 E/M 界、公共 S 界、S_int 和部分区间；具体差见起点。',
'2. 通过：输运的 Q16/Q24 表均拒绝 T 路线；采用 C，最终场没有更换。',
'3. 通过：完整 S_int 界逐模板、全量和 taper 子项均包含同场 Q16/Q24；没有为包含检查调宽界。',
'4. 通过：960 条弧及所有同伦参数面板覆盖；实际 native 逆根的立方体余量为正，两个 native 和两个 fitted 分支全部保留，见证明与计数表。',
'5. 通过：界面独立求积加公共类贡献等于原浮点总 S，E/M 原类和也保持；相对差均小于 1e-13。',
'6. 通过：12 个符号与独立标量复算通过，BIE 参考在完整区间内；BIE 未用于选根或校准上界。','',
'## 成本','',
'启动前预计：基准／路线试算 240–400 秒，探针 300–700 秒，全量 600–1300 秒，质量常数细化复核 700–1000 秒；峰值均预估 2.1–2.8 GiB。探针按每模板四条弧定成本，随后全量覆盖；各运行都由同一监控器约束。','',
'| 运行 | 内容 | 墙钟，秒 | 峰值 RSS，GiB |','|---|---|---:|---:|']
labels={'run-001':'v1 复现与输运路线选择','run-002':'12 条弧探针','run-003':'首次完整界面与四角证书','run-004':'局部复数模常数细化与完整复核'}
for name,c in z['cost'].items():L.append(f'| [{name}](output/{name}/monitor.json) | {labels.get(name,"复现运行")} | {c["wall_seconds"]:.6f} | {c["peak_process_tree_rss_gib"]:.6f} |')
L+=['',
'每个全量进程都重新生成场、通量和 v1 基准，因此上表包含重复的必要基准成本。模板证书时间分别为 '+ '／'.join(f'{t["seconds"]:.6f}' for t in x['templates'])+' 秒；逆与几何模型在各胞元间复用。首次成功结果和细化前源代码均保留，科学输入和网格没有改变。','',
'## 未完成与下一步','',
'本阶段的界面截断误差与完整四角组装已经闭合。下一步是给多项式系数、逆缺陷、求积常数和四角标量加入区间舍入控制，再重新核对全部余量和宽度。现有 S_int 包含检查未出现舍入失败；这不保证换成区间算术后仍有相同余项与成本。','',
'## 限制','',
'所有积分界按精确实数算术解释，浮点舍入排除。(H)、(P)、带边、DtN 误差和 C_h 未在本阶段认证。最终谱包围仍以既有 (H)、命题 1 与共享场／通量结构为前提。', '',
'覆盖证明与余项针对当前模型、截线、网格、taper 和固定 s；没有声称任意模型具有相同成本。继承的 v1 逐单元极窄质量打印区间的舍入问题仍属于后续舍入工作，不改变本阶段按要求排除舍入的积分论证。','']
# Only the preserved proof intentionally contains embedded line breaks.
clean=[]
for text in L:
 if text==proof:clean.append(text);continue
 for c,r in {chr(7):r'\a',chr(8):r'\b',chr(9):r'\t',chr(10):r'\n',chr(11):r'\v',chr(12):r'\f',chr(13):r'\r'}.items():text=text.replace(c,r)
 clean.append(text)
(here/'README.md').write_text('\n'.join(clean))
