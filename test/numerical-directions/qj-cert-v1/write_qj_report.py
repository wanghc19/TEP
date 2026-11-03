"""Write the Chinese first-implementation report from retained scalar records.
Input: completed certificate run. Output: README.md in the experiment directory.
"""
import argparse,json
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('run');a=p.parse_args();run=Path(a.run);sd=run/'science';here=Path(__file__).resolve().parent
x=json.loads((sd/'certificates.json').read_text());z=json.loads((run/'analysis.json').read_text());i=json.loads((sd/'inventory-exact.json').read_text());b=json.loads((sd/'baseline.json').read_text());f=json.loads((sd/'exact-flux.json').read_text())
rr=run.resolve().relative_to(here).as_posix();sdir=rr+'/science';fmt=lambda v:format(v,'.17g');g=lambda v:format(v,'.12g')
L=['# Goerisch 数量的截断误差界：首次实现','',
'`qj-cert` = certificate for the Goerisch quantities q and J（Goerisch 数量 q、J 的证书）；v1 = 版本 1。FEM = finite element method（有限元法）；DtN = Dirichlet-to-Neumann；RT3 = Raviart–Thomas 三阶通量；P3 = 三次有限元；JSON = JavaScript Object Notation；CSV = comma-separated values；RSS = resident set size（常驻内存）；BIE = boundary integral equation（边界积分方程）。','',
'## 目的','',
f'精确实数算术模型下，E、M 的全部积分部分已有截断误差界；S 的精细积分界覆盖其浮点值的 **{100*z["S_smooth_share"]:.6f}%**。剩余拟合界面贡献为 {z["S_interface_float_value"]:.12e}，约占 {100*(1-z["S_smooth_share"]):.6f}%，仍使用浮点求积。完整 S 另有粗上界 {x["S_upper_coarse"]:.12g}，但不能通过四角符号测试。', '',
f'部分认证区间为 [{fmt(x["corners_partial"]["L"])}, {fmt(x["corners_partial"]["U"])}]，宽 {x["corners_partial"]["width"]:.14e}；独立高精度标量重算的宽度罚项为 {100*float(z["decimal_partial_corners"]["penalty"]):.6f}%。完整认证四角区间尚未得到。', '',
'检查 4 部分失败：左右 taper 质量的打印区间没有逐字包含 Q24，差约 $10^{-25}$，而形式上的截断余项约 $10^{-35}$。这说明当前浮点评价的舍入已大于所报截断余项。按工作规则停止进一步实验，保留该结果；没有扩大误差界来使检查通过。下面的“给界”均指排除舍入后的公式，不表示这些十进制打印端点已有机器舍入保证。','',
'## 起点与输入','',
'求解代码只复制自 [gap-ends-v1](../gap-ends-v1/README.md)。物理模型、g48 网格、P3 节点场、13 胞元延拓、RT3 通量盒和 taper 保持；谱端点为 $1.32^2,2.37^2$。每次重新做 P2 搜索、P3 求根和 RT3 通量计算，不读取旧 MAT 文件。', '',
'理论按 [问题说明](../../../research/explorations/numerical-directions/qj-bounds-problem.md)、[证明](../../../research/explorations/numerical-directions/qj-bounds-proof.md) 和 [经理复核](../../../research/explorations/numerical-directions/qj-bounds-proof-check.md)。本文没有独立核验其中引用的外部定理。固定 $s=q_{16}$，在全部误差界中不再替换它。BIE 数值 $2.428728670022710$ 只用于最后的包含检查。', '',
f'本次基准：根 {fmt(b["generation"]["frequency"])}，$q={fmt(b["q"])}$，$J={fmt(b["J"])}$，旧基宽 {b["width"]:.16e}。相对参考差分别为 {b["root_relative"]:.3e}、{b["q_relative"]:.3e}、{b["J_relative"]:.3e}、{b["width_relative"]:.3e}。', '',
f'主记录：[certificates.json]({sdir}/certificates.json)、[analysis.json]({rr}/analysis.json)、[inventory-exact.json]({sdir}/inventory-exact.json)。','',
'## 复现命令','',
'在仓库根目录执行，输出目录须不存在。以下编号接在保留的四次运行之后。','',
'```sh',
'python3 test/numerical-directions/qj-cert-v1/exact_basis.py',
'python3 test/numerical-directions/qj-cert-v1/launch_qj.py --stage certificates --output test/numerical-directions/qj-cert-v1/output/run-005',
'python3 test/numerical-directions/qj-cert-v1/launch_checks.py --output test/numerical-directions/qj-cert-v1/output/run-006',
'python3 test/numerical-directions/qj-cert-v1/analyze_qj.py test/numerical-directions/qj-cert-v1/output/run-005',
'python3 test/numerical-directions/qj-cert-v1/write_qj_report.py test/numerical-directions/qj-cert-v1/output/run-005',
'```','',
'MATLAB 由 `diagnostics-v1/monitor.py` 启动，使用 R2023b、11 MATLAB/OpenMP 线程和 `OMP_DYNAMIC=FALSE`；按任务要求对启动请求提权。`direct_pipeline.m` 已完整保留，`build_pipeline.py` 只用于重建本地副本。run-002 的初版粗界源代码另存于 `coarse-certificate-source.txt`、`coarse-geometry-source.txt`，用于解释初版记录；当前复现命令采用改进实现。','',
'## 元素分类表','',
'逐存储节点检查三个中边节点与两端点算术中点是否相等。左／中／右严格仿射模板单元数为 1909／5690／4679；非界面但不严格仿射的数为 3861／0／1073，最大坐标差 $1.1102230246251565\times10^{-16}$。这部分另列为公共二次几何，采用有理积分界。没有用坐标容差把它们算成仿射单元。','',
'下表为全部 27 胞元的未归一化 Q16 贡献和 $|Q_{16}-Q_{24}|$。native 的质量修正采用带符号 band 公式，属于该行所覆盖胞元的修正；它不改变能量。','',
'| native 类别 | 元素数 | E | M_nat | band 修正 | ΔE | ΔM_nat | Δ修正 |',
'|---|---:|---:|---:|---:|---:|---:|---:|']
for r in z['native_classes']:
 name={'affine_untapered':'仿射，无 taper','quadratic_untapered':'二次几何，无 taper','taper':'taper（含界面）'}[r['class']]
 L.append(f'| {name} | {r["count"]} | '+ ' | '.join(f'{r[k]:.12e}' for k in ['E16','Mnative16','C16','E_difference','Mnative_difference','C_difference'])+' |')
L+=['','| fitted 残差类别 | 元素数 | S，Q16 | $|Q_{16}-Q_{24}|$ | 截断误差处理 |','|---|---:|---:|---:|---|']
for r in z['residual_classes']:
 name,status={'common_affine_untapered':('公共仿射，无 taper','求积精确性'), 'interface_untapered':('拟合界面，无 taper','浮点值；有粗上界'), 'taper':('taper（含界面）','公共部分给界；界面部分浮点'), 'common_quadratic_untapered':('公共二次几何，无 taper','有理积分证书')}[r['class']]
 L.append(f'| {name} | {r["count"]} | {r["S16"]:.12e} | {r["difference"]:.3e} | {status} |')
L+=['',
'计数与贡献来自 [native-classes.csv]('+sdir+'/native-classes.csv) 和 [residual-classes.csv]('+sdir+'/residual-classes.csv)。taper 的拟合界面子项单独记录在 `inventory-exact.json` 的 `fitted(:,:,2)`；其余 `fitted(:,:,1)` 是该类总 S。E、M、S 的类和与基准均在 $10^{-13}$ 相对容差内。','',
'积分状态：仿射无 taper 的 E、M、S 由精确性给界；二次 native 的无 taper 质量也是多项式精确积分；其能量用有理证书；全部 taper E/M 和公共 taper S 用带余项模型。真实质量修正用 $C_0\pm B$ 给界。只有拟合界面 S 的精细值仍浮点。','',
'## 精确 RT3 基','',
'以原 24 维 raw 单项式 RT3 空间为坐标。12 个边列取证明 (3.16) 的多项式提升，边迹为 $(2m+1)L_m$，其余边迹严格为零；12 个内部列取有理矩阵精确对偶的内部列，其全部边迹为零。所有 raw 系数均为整数，最大绝对值 69552。', '',
'[exact_basis.py](exact_basis.py) 用 Python Fraction 计算和验证 72 个完整迹多项式等式及 432 个矩阵条目；[exact-basis-check.json](exact-basis-check.json) 全部通过。该检查不是在边上采样。参考基是 [exact_rt3_basis.m](exact_rt3_basis.m)。', '',
'从旧基表示转换 raw 多项式；内部坐标随表示改变，12 个边坐标由同一主边数据重新赋值。每个局部边系数按 `G.phase * master` 定义，胞间端口来自同一个主端口向量，顶底边共享主编号并乘精确 Bloch 相位。参数反向由 $(-1)^{m+1}$ 处理；外侧竖直边的主系数严格为零。这里把共享表达式视为精确算术定义，浮点求值和系数转换的舍入留待后续处理。', '',
f'运行前预期 $|\Delta S|\le10^{{-16}}$。实测原 S 为 {f["S_before"]:.17e}，新 S 为 {f["S_after"]:.17e}，差 {f["S_change"]:.17e}；宽度相对变化 {f["width_relative_change"]:.3e}。主边重建差和竖直外边主矩均为 0，与旧约 $8\times10^{{-14}}$ 基迹缺陷仅需极小修正的预期一致。此差是浮点诊断；精确容许性来自整数迹与主数据共享。','',
'## 质量修正','',
'实现 (5.5) 的一维边界迹积分。曲线用中心 Taylor 多项式和显式余项；位移 $D_0$ 取该模型界与 (5.7) 的较小者，$D_1$ 用导数模型界，$Q_1$ 用线性插值边导数在两端的最大范数。$V_e$ 是已知 cubic 边迹的系数范数上界。', '',
'$L_e$ 覆盖该弧相邻两 native 单元。覆盖理由是：把 fitted 修正乘 $\tau\in[0,1]$ 后，(3.1) 的余量仍小于 1；这两个单元并集的外边保持不动。因此其同伦像留在该并集，扫掠线段不会被遗漏。梯度界使用全单元 Jacobian 下界、逆矩阵范数界和场导数系数范数，不使用节点采样最大值。','',
'| 模板 | $C_0$ | 一维积分余项 | $\sum B_e$ |',
'|---|---:|---:|---:|']
for t in x['templates']:L.append(f'| {t["template"]} | {t["C0"]:.14e} | {t["C0_error"]:.3e} | {t["mass_bias"]:.14e} |')
mc=x['mass_correction']
L+=['','| 质量修正的胞元类别 | C0 | 偏差界 | 一维积分余项 |','|---|---:|---:|---:|']
for name,label in [('untapered','无 taper'),('taper','taper')]:
 c=z['correction_classes'][name];L.append(f'| {label} | {c["C0"]:.14e} | {c["bias"]:.14e} | {c["integration_error"]:.3e} |')
L+=['',
f'总 $C_0={mc["C0"]:.17e}$；原 band 修正 {mc["band16"]:.17e}；差 {mc["difference"]:.12e}，被 $\sum B_e={mc["bias"]:.14e}$ 覆盖。相对 $9.4\times10^{{-12}}$ 预算为 **{mc["bias_budget_ratio"]:.6f} 倍**。另自愿扩大质量半宽 $10^{{-13}}$，该宽化不作为浮点舍入保证。', '',
'初版全胞元梯度常数给出 $3.7982076706\times10^{-9}$；使用允许的 (5.7) 与相邻单元覆盖后得到上表结果。偏差仍超分项预算，TODO：实现带分支证明的精确 sliver 积分，而不是继续把 band 的 16／24 阶差当作界。逐弧常数与偏差保存在三个 `*-mass-arcs.csv`，后处理独立重算 (5.6) 及总和通过。', '',
'## 几何证书','',
'本次生成记录核查了约束边、双侧界面关联、边关联数、正定向、胞元覆盖、材料两侧、顶底配对和胞间平移配对。新增证书以直边顶点三角形为起点：$(DF-B)B^{-1}$ 仿射，取三个顶点的 Frobenius 范数最大值即给出全三角形界；Jacobian 二次多项式的极值枚举顶点、三边驻点和内部驻点，未用 Gauss 点代替全域测试。', '',
'fitted 修正按 (3.6)、(3.8) 求范数界，再用 (3.3) 给行列式下界。所有三模板通过 $\eta_{\rm native}<1$、$\eta_{\rm geom}<1$。','',
'| 模板 | native η 最大值 | fitted η 最大值 | native det 下界 | fitted det 下界 |',
'|---|---:|---:|---:|---:|']
for t in x['templates']:
 q=t['geometry'];L.append(f'| {t["template"]} | {q["native_eta_max"]:.10g} | {q["fitted_eta_max"]:.10g} | {q["native_det_min"]:.12e} | {q["fitted_det_min"]:.12e} |')
L+=['',
'逐单元数据在三个 `*-geometry.csv`。坐标、函数值和矩阵运算均按排除舍入的模型解释；本节不是对浮点网格生成算法的舍入认证。','',
'## 多项式模型积分','',
'[poly2.m](poly2.m) 实现加、乘、共轭所需运算、按总次数截断、有限几何级数倒数、sin/cos Taylor 余项、三角形矩和 Bernstein 范围。误差按证明 (4.4)–(4.6) 累加。倒数的分母严格正性来自全域几何界；曲边能量先组成分子，再求积分与余项。公共二次几何残差先形成三个小残差分子，再平方，保留抵消。', '',
'对二次行列式 j，用已证明的最小／最大值选 $d_0$ 与 $\kappa$；有限几何多项式在三角形上用 $i!j!/(i+j+2)!$ 精确矩积分。最大几何级数次数为 '+str(max(t['max_rational_degree'] for t in x['templates']))+'，最大 κ 为 '+g(max(t['max_kappa'] for t in x['templates']))+'。taper 采用原物理坐标的 sin/cos 公式，Taylor 阶数 12；C0 的一维曲线模型阶数 18。', '',
'| 类别 | E 界半宽 | M_nat 界半宽 | S 精细界半宽 |',
'|---|---:|---:|---:|']
L.append('| 仿射无 taper | 0（精确性） | 0（精确性） | 0（精确性） |')
L.append(f'| 二次几何无 taper | {sum(t["E_error"] for t in x["templates"]):.12e} | 0（精确性） | {sum(t["S_error"] for t in x["templates"]):.12e}（公共部分） |')
L.append(f'| taper | {sum(t["E_taper_error"] for t in x["templates"]):.12e} | {sum(t["M_taper_error"] for t in x["templates"]):.12e} | {sum(t["S_taper_error"] for t in x["templates"]):.12e}（公共部分） |')
L+=['',
'无 taper 仿射 E、M、S 的多项式次数分别不超过 4、6、8；二次 native 质量不超过 8。Duffy 因子已计入，16 阶规则超过所需 3／4／5 阶，截断误差为零。所列非零半宽采用预分配的保守积分容差，通常大于实际模型尾项。', '',
'已知积分核查覆盖加、乘、截断、带输入误差倒数、sin/cos、三角形矩、三角形有理积分及 Bernstein 范围。run-004 的单元诊断通过；对超出截断余项精度的浮点参考比较使用 $10^{-12}$ 诊断容差，该容差没有被加入积分证书。它不是区间算术测试。', '',
f'全局 E/M 界均包含 Q24；曲边 E、taper E、公共二次 S 和公共 taper S 的非零宽界逐模板包含 Q24。左右 taper M 的模型余项仅 {x["templates"][0]["M_taper_error"]:.3e}／{x["templates"][2]["M_taper_error"]:.3e}，打印中退化成点，与 Q24 差分别 2.585e-25／1.551e-25，**逐字包含失败**。仿射精确性类的 Q16／Q24 浮点差也仅作舍入诊断，不将其当作截断误差。','',
'## 界面单元残差','',
f'精细界已覆盖 S 值 {z["S_smooth_value"]:.14e}；剩余拟合界面（含 taper 界面）Q16 贡献 {z["S_interface_float_value"]:.14e}。没有给它的小误差求积证书；保留浮点值。', '',
'对各 fitted 界面图构造 native 分支的光滑逆映射延拓。采用 (4.8)–(4.9) 的常矩阵压缩测试；三个中心模板整图测试不足的情况改用 4×4 参数覆盖。原大参考立方体上的 κ 小于 1 保证相邻覆盖中的逆根一致，覆盖的每一小块再独立核查自映射。全部 1920 个界面模板图最终有延拓证书，3 个用到了分块。','',
'| 模板 | 延拓图数 | 分块图数 | 未通过图数 | 最小自映射余量 |',
'|---|---:|---:|---:|---:|']
for t in x['templates']:L.append(f'| {t["template"]} | {t["inverse_extension_count"]} | {t["inverse_extension_refined"]} | {t["inverse_extension_failures"]} | {t["min_inverse_selfmap_margin"]:.10g} |')
ex=x['S_extension']
L+=['',
f'对无 taper 界面部分，代码用相邻 native 分支和延拓分支的梯度界之和作为 $G_j$，以共同边上值相等和位移界试算 $U_j$，面积用 (5.17)。**尚未检查整条扫掠线段都落在同一个已证明的延拓域内，因此该 $U_j$ 与完整 η 界尚未闭合。** 当前预算试算 $\eta_s= {ex["eta"]:.12g}$，$\eta_s^2={ex["eta_squared"]:.12e}$。目标 $0.005S$ 对应允许的 η 约 {ex["allowed_eta"]:.12e}；当前 η 试算为它的 **{z["eta_budget_ratio"]:.6g} 倍**。该试算没有作为 S 的可靠上界；它也不是实际差的下界。即使补上路径覆盖，当前粗梯度估计仍达不到预算。', '',
'该 η 预算试算本身平方已远大于整个目标残差，且值差路径覆盖尚缺，因此没有继续认证光滑延拓残差 $S_0$。输出中的 `inflation_if_S0_equals_float` 只是令 $S_0$ 等于原 S 的预算情景，**不是实测的 $S_0$**。taper 界面的延拓误差也未继续量化；它仍列在浮点界面贡献中。TODO：以分支残差多项式差与 cut-panel 积分替代当前粗梯度和界，不能把小几何位移当成足够小的残差误差。', '',
'为给出完整但宽的 $S_+$，另在每个 fitted 界面单元对 (5.13) 使用全域系数范数、相邻分支覆盖和 Jacobian 上下界。该粗界包含全部 taper 界面，不依赖有限 Newton 求值误差；它丢失了小残差的抵消，仅用于展示缺口。','',
'## 四角区间','',
'截断误差公式的浮点评价值如下，全部使用同一原生 P3 节点场和整数基通量。','',
'| 量 | 区间或上界 | 状态 |','|---|---|---|',
f'| E | [{fmt(x["E"][0])}, {fmt(x["E"][1])}] | 全部积分部分给界，舍入排除 |',
f'| M | [{fmt(x["M"][0])}, {fmt(x["M"][1])}] | 全部积分部分给界，含 C0 偏差；舍入排除 |',
f'| 公共部分 S | [{x["S_smooth"][0]:.17e}, {x["S_smooth"][1]:.17e}] | 精细积分界 |',
f'| 界面 S | {x["S_interface_floating"]:.17e} | 浮点 |',
f'| 完整粗上界 S+ | {x["S_upper_coarse"]:.17g} | 全积分粗界，不能通过符号 |',
f'| 部分认证 S+ | {x["corners_partial"]["S_upper"]:.17e} | 公共部分上界＋浮点界面 |','',
'| 四角组装 | L | U | 宽度 | 对基准罚项 | 符号 |',
'|---|---:|---:|---:|---:|---|',
f'| 完整粗界 | — | — | — | — | {z["coarse_signs_passed"]}/12 通过，未得区间 |',
f'| 部分认证 | {fmt(x["corners_partial"]["L"])} | {fmt(x["corners_partial"]["U"])} | {x["corners_partial"]["width"]:.14e} | {100*z["printed_partial_width_penalty"]:.6f}% | 12/12 通过 |','',
f'独立 Decimal 标量复算宽度为 {float(z["decimal_partial_corners"]["width"]):.15e}，罚项 {100*float(z["decimal_partial_corners"]["penalty"]):.6f}%；它只减少四角标量评价的抵消，不是舍入认证。部分认证区间包含 BIE 参考。', '',
'完整粗界的四角 H 和 $D_\mu$ 都为负，只有 $-D_\nu$ 四项为正。部分认证组的最小 H／$D_\mu$／$-D_\nu$ 分别为 '+ '／'.join(f'{min(row[k] for row in x["corners_partial"]["signs"]):.12g}' for k in range(3))+'。', '',
f'预算分配：E 总半宽约 {(x["E"][1]-x["E"][0])/2:.6e}，小于 $2.2942\times10^{{-11}}$；M 总半宽约 {(x["M"][1]-x["M"][0])/2:.6e}，超过 $9.4461\times10^{{-12}}$；公共部分 S 额外半宽约 {(x["S_smooth"][1]-x["S_smooth"][0])/2:.6e}，小于 $1.4736\times10^{{-12}}$。界面 S 未消耗一个已证明的小预算。分项质量预算超额时，联合部分认证宽度仍只增加约 0.62%；它不能替代缺失的界面界。','',
'## 核查','',
'1. 通过：P3 根、q、J 和 $4.4537\times10^{-9}$ 基宽在同一进程复现，差见起点表。',
'2. 通过：全部元素类别、计数、贡献和状态已列；E/M/S 类和相对基准差小于 $10^{-13}$。',
'3. 通过：整数算术边迹检查；S 改变量低于预先声明的 $10^{-16}$，主边与外边结构约束核对为零。',
'4. **部分完成**：多项式库已知积分诊断通过；E/M 全局和 E/S 非零宽分类界包含 Q24；左右 taper M 的打印区间逐字包含失败。舍入未处理，没有为通过核查而加宽。',
'5. 通过：$C_0\pm(\sum B_e+\varepsilon_0)$ 包含原 band 修正，独立逐弧重算通过；偏差超过指定分项预算 2.75 倍。',
'6. **部分完成**：部分认证四角的 12 个符号通过且含 BIE 参考；完整粗界只有 4/12 符号通过，未给出完整认证区间。','',
'## 成本','',
'运行前估计：首轮 240–600 秒、2.2–2.8 GiB；粗界轮 300–1500 秒、2.2–2.8 GiB；改进轮 300–1200 秒、2.2–2.8 GiB；库核查 10–30 秒、0.5–1.2 GiB。各运行软／硬限为 30／40 分钟，3 GiB。','',
'| 运行 | 内容 | 墙钟，秒 | 峰值 RSS，GiB |','|---|---|---:|---:|']
labels={'run-001':'基准、旧／新基分类、整数基','run-002':'基准及初版粗界','run-003':'taper 模型、局部质量常数、几何／逆映射证书','run-004':'多项式库核查'}
for name,c in z['numerical_runs'].items():L.append(f'| [{name}](output/{name}/monitor.json) | {labels.get(name,"复现运行")} | {c["wall_seconds"]:.6f} | {c["peak_process_tree_rss_gib"]:.6f} |')
L+=['',
'每轮重新生成场和通量，因此上表包含重复的基准与分类成本。第三轮三个模板证书计算分别为 '+ '／'.join(f'{t["seconds"]:.6f}' for t in x['templates'])+' 秒；几何和模型在模板内复用，实际字段仍按每个胞元累加。所有运行均正常退出；科学未完成项由上述检查 4／6 和界面预算明确记录。','',
'## 未完成与下一步','',
'1. TODO：对 taper 质量等极窄区间引入带舍入控制的模型运算和输出，再恢复逐字 Q24 包含检查。现阶段不宣称打印端点已被验证。',
'2. TODO：用精确 sliver 路线降低质量偏差，或在经理接受联合预算时保留当前质量界；本线程没有把超额分项预算标为通过。',
'3. TODO：实现原始混合网格 S 的 cut-panel／小残差分支差积分。当前光滑延拓的值差路径覆盖尚缺，粗梯度预算试算也远超预算，未计算可信 $S_0$，拟合界面仍有 11.8537% 的浮点 S 贡献。',
'4. TODO：取得界面 S 上界后重新检查全部 12 个符号，用 (6.8) 得完整四角区间并比较 1% 目标。当前只有部分认证区间达到了这个宽度目标。','',
'## 限制','',
'舍入排除；(H)、(P)、带边、DtN 误差和 $C_h$ 不在本阶段处理。所给 E/M 和粗 S 公式以这些模型／几何／共享节点定义和既有证明为基础；当前浮点实现不提供机器舍入保证。', '',
'原场始终按共享 P3 节点与相同边参数定义；单项式转换作为计算表达式，其舍入也在排除项中。整数 RT3 基则避免了参考基真实法向迹缺陷。不能把 16／24 阶接近、一个小 Newton 残差、一个表面态扫描或部分认证四角区间升级为完整连续特征值保证。','']
# Prose entries are single logical lines; preserve LaTeX escapes in them.
control={chr(7):r'\a',chr(8):r'\b',chr(9):r'\t',chr(10):r'\n',chr(11):r'\v',chr(12):r'\f',chr(13):r'\r'}
for idx,line in enumerate(L):
 for char,literal in control.items():line=line.replace(char,literal)
 L[idx]=line
(here/'README.md').write_text('\n'.join(L))
