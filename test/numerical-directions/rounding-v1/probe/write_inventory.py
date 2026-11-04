"""Write the rounding inventory from static rows and retained numerical records.
Input: repository working directory. Output: one authorized research inventory.
"""
from pathlib import Path
from collections import Counter
import json,csv,math,runpy
root=Path.cwd();here=Path(__file__).resolve().parent
runpy.run_path(str(here/'inventory_rows.py'));rows=json.loads((here/'inventory-rows.json').read_text())
read=lambda p:json.loads((root/p).read_text())
qpath='test/numerical-directions/qj-cert-v2/output/run-004/science/'
q=read(qpath+'interface-certificate.json');q0=read(qpath+'certificates.json');dd=read('test/numerical-directions/h-core-v1/output/run-002/science/result.json');cf=[read('test/numerical-directions/h-dtn-v1/output/'+r+'/science/result.json') for r in ['run-006','run-008']]
qgeom=[]
for name in ['left','center','right']:
 data=list(csv.DictReader((root/qpath/(name+'-geometry.csv')).open()));item=min(data,key=lambda x:float(x['det_min']));qgeom.append({'template':name,'element':int(item['element']),'det_min':float(item['det_min']),'det_max':float(item['det_max']),'relative':float(item['det_min'])/float(item['det_max'])})
bs=[]
for n in ['run-009','run-010','run-007','run-011']:
 d=read('test/numerical-directions/h-cert-v1/output/'+n+'/science/result.json');scale=max(sum(abs(complex(d['C_real'][i][j],d['C_imag'][i][j]))+abs(complex(d['E_real'][i][j],d['E_imag'][i][j])) for j in range(21)) for i in range(21));bs.append({'run':n,'material':d['material'],'lambda':d['lambda'],'gamma':d['tests'][-1]['gamma'],'norm_scale_bound_from_centers':scale,'relative':d['tests'][-1]['gamma']/scale,'cancellation_ratio':d['gram_cancellation_ratio']})
E=q['full_interval']['E'];M=q['M'];margin={'QE':{'halfwidth':(E[1]-E[0])/2,'relative':(E[1]-E[0])/(E[0]+E[1]),'source':qpath+'interface-certificate.json/full_interval.E'},'QM':{'halfwidth':(M[1]-M[0])/2,'relative':(M[1]-M[0])/(M[0]+M[1]),'bias':q['mass_bias'],'bias_budget_remaining':9.4e-12-q['mass_bias'],'source':qpath+'interface-certificate.json/M,mass_bias'},'QI':q['templates'],'QG':qgeom,'BB':bs,'DD':{k:dd[k] for k in ['gamma_2','epsilon','safe_margin','shifted_min_abs_pivot','min_abs_pivot','tail_Gram_min','H_defect']},'AR':{'lower_negative_margin':1.3972238392e-4,'upper_positive_margin':7.5205045129e-3,'source':'research/explorations/numerical-directions/h-cert-proof.md:1853','native_run_JSON_available':False}}
(here/'inventory-margins.json').write_text(json.dumps(margin,ensure_ascii=False,indent=2)+'\n')
# Refine source locations without modifying their owners.
for r in rows:
 if r['stage']=='B' and r['quantity']=='零负指标单调延伸与K+':r['line']=30
 if r['stage']=='qj' and r['quantity']=='BIE参考与Q16/Q24诊断':r['file']='test/numerical-directions/qj-cert-v2/interface_certificate.m';r['line']=48
 if r['quantity']=='最终L/U和宽度打印':r['line']=14
 if r['quantity']=='D的epsilon、gamma与最终结论':r['line']=25
 if r['quantity']=='非负余项与全局聚合':r['margin']='QE最严半宽约2e-12；flat gamma_(1.7e5)约2e-11不够'
 if r['quantity']=='LDL惯性计数':r['cost']='试点Arb 2.07秒，含监控17.55秒'
 if r['quantity']=='第二特征值的近贴边shift':r['cost']='较宽shift试点已验证，见下文'
(here/'inventory-rows.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2)+'\n')
for r in rows:
 lines=(root/r['file']).read_text().splitlines();assert 0<r['line']<=len(lines),(r['file'],r['line'])
sc=Counter(x['stage'] for x in rows);tc=Counter(x['treatment'] for x in rows)
text=r'''# 舍入认证清单

## 目的

共100行，覆盖 qj、A、B、C、D 和标量/矩阵交接。默认71项 E1、7项 E3、9项 E4、10项 E0；另3项为诊断或可选快速分支。E2 不作为默认必需路径。现有四角区间与 (H) 均尚未去掉舍入排除，本清单没有把它们升级为计入舍入的结果。

依据为 [paper.tex 第3–6节](../../../draft/fem-goerisch/paper.tex)、[OP-ND-5](../../projects/eig-apost/implementation/open-problems.md:132)、[qj-bounds-proof.md 定理6.1](qj-bounds-proof.md) 和 [h-cert-proof.md §2–6](h-cert-proof.md)。本文只作清点、工具检查和可选的有限矩阵试点；数值实现写在后续阶段。

四类依赖：1为数据对象本身的可容许性，2为评价与组装，3为符号/惯性/几何决定，4为超越函数、常量及交接。E0 表示精确结构或任意试探数据的选择无需认证求解过程；E1 用 python-flint 重算；E3 用近似因子/向量加严格残差验证；E4 作有向交接。表中 other 的诊断不进入最终证书。

## 工具检查

两项均通过。`conda run -n octave python -I` 在沙箱中直接导入 python-flint 0.9.0、numpy 2.5.4、scipy 1.18.1。MATLAB 经提权的 monitor.py 启动，11线程、OMP_DYNAMIC=FALSE，14.2205秒、峰值0.639786 GiB。`save(...,'-v7')` 的实数与复数矩阵，分别将实部、虚部与 MATLAB 同次导出的 uint64 位模式比较，全部逐位一致；包含极大/极小正规数及最小次正规数。double 到 Arb 与其精确二进制有理数比较也通过。

记录在 [smoke-results.json](../../../test/numerical-directions/rounding-v1/probe/smoke-results.json) 及 [run-001/monitor.json](../../../test/numerical-directions/rounding-v1/probe/run-001/monitor.json)。这个检查证明导出层保持数据，不证明任意派生数组是可容许对象或已向外舍入。

本机 `arb_mat` 没有直接暴露 Cholesky/LDL 方法；有 `eig/inv/solve`，`acb_mat.eig` 可选 rigorously enclosed 的默认/Rump算法，也有明确不带误差的 `algorithm='approx'`。高重根需处理 cluster。可以用近似 Cholesky/LDL 或向量作为数据，再以球残差认证；不必逐个隔离全部1122个特征值。

复现工具检查：

```sh
python3 test/numerical-directions/rounding-v1/probe/smoke_launch.py --output test/numerical-directions/rounding-v1/probe/run-001
conda run -n octave python -I test/numerical-directions/rounding-v1/probe/python_smoke.py test/numerical-directions/rounding-v1/probe/run-001/science/smoke.mat test/numerical-directions/rounding-v1/probe/smoke-results.json
```

重跑 MATLAB 检查使用未占用的运行编号。

## 总表

以下是一张按阶段排序的完整表。成本为实施后的单阶段预计运行范围，尚未测量；共享步骤的成本不能逐行相加。工程工时另列。相对余量只在给定尺度内有意义；未保留范数/分母的地方明确记为未知。

余量代号及 JSON 来源：

- **QE/QM/QF/QI**：`test/numerical-directions/qj-cert-v2/output/run-004/science/interface-certificate.json` 的 `full_interval.E`、`M/mass_bias`、`full_interval.signs/L/U`、`templates.min_selfmap_margin/min_actual_branch_margin`。QE半宽2.00018e-12、相对1.7437e-13；QM半宽6.90203e-12、相对1.46136e-12；QF最小12符号0.945405；QI最小自映射0.0315321、实际分支0.0515773。
- **QS/QG/QTaper**：同次 `certificates.json` 的 `S_smooth`、`templates.geometry`，以及 `interface-certificate.json` 的 `templates.smooth_taper_remainder/taper_correction_bound`。QS公共S上界2.5978064967e-10；公共区间相对宽约9.47e-7。原逆延拓最小自映射0.0154489。G的相对Jacobian余量可从同目录 `*-geometry.csv` 的同元 det_min/det_max 读取。**QT**：同次 `exact-flux.json`，外墙主矩0、共享主边重建差0；这些零只覆盖当前构造中的浮点相位。
- **QFirst**：`draft/fem-goerisch/paper.tex:300` 的一阶交集区间；当前 qj JSON 未单列此对象，后续须重新导出证书。
- **AR**：A 没有既存运行 JSON，现数字来自 `h-cert-proof.md:1853` 及 MATLAB/原 Python 源码；下端1.3972238392e-4、上端7.5205045129e-3。表中没有伪造一个已测得的相对矩阵余量。后续必须逐面板记录矩阵norm和有向符号界。
- **BR/BB/BH/BG**：`h-cert-v1/output/run-009,010,007,011/science/result.json`，依次为0.12下/上端、0.20下/上端；字段 `gram_cancellation_ratio/eps_*/tests.gamma/tail/d_per/form_inverse`。最小BB为run-007、M10的0.00428912961539；以该JSON中 C/E 的绝对行和0.543877386455作参考尺度，相对值0.00788621。BG 的附加响应界没有被主链采用。
- **CT/CG/CR/CI/CP/CH/CL**：`h-dtn-v1/output/run-006,008/science/result.json` 的 `trace_check`、`first/bulk`、`r/K_r/gap`、`eps_Q/eps_R/eps_Z`、`series_weight_bound`、`A_H`、`min_lower_raw`；幂/几何补充值在 `h-dtn-v1/output/run-011/science/fe-dtn.json` 的 `series/geometry`。CR约3.8954e-8，K r约1.0903e-5；CI量级分别1e-14、1e-14、1e-12；CH=0.99970696205。
- **DR/DH/DC/DD/DP**：`h-core-v1/output/run-002/science/result.json` 的 `tail_Gram_min`、`H_defect`、`c_W/delta`、`gamma_2/epsilon/safe_margin`、`shifted_min_abs_pivot`。DD为0.365373690844减2.06203317645e-9；DP为1.10754385685e-10。DI为 `material.normalized_error=1.22086658301e-10`。**SM**为本次 smoke JSON。

派生余量、来源及几何同元比值另存 [inventory-margins.json](../../../test/numerical-directions/rounding-v1/probe/inventory-margins.json)，它是对已有记录的提取，不是新的舍入认证结果。

'''
headers=['阶段','file:line','量','类','操作与规模','所进入的不等式','当前绝对/相对余量及来源','处理','预计成本','main risk']
text+='| '+' | '.join(headers)+' |\n|'+ '|'.join(['---']*len(headers))+'|\n'
for r in rows:
 link=f"[{Path(r['file']).name}:{r['line']}](../../../{r['file']}#L{r['line']})"
 cells=[r['stage'],link,r['quantity'],str(r['kind']),r['operation'],r['inequality'],r['margin'],r['treatment']+'：'+r['proposal'],r['cost'],r['risk']]
 text+='| '+' | '.join(x.replace('|','&#124;').replace('\n',' ') for x in cells)+' |\n'
text+=r'''

逐阶段行数为 qj 32、A 11、B 16、C 17、D 12、handoffs 12。行记录在 [inventory-rows.json](../../../test/numerical-directions/rounding-v1/probe/inventory-rows.json)，可用于后续逐项销账。

## 数据本身的可容许性

**可以直接冻结的量。** 任意主节点/内部试探系数、响应多项式系数、预条件矩阵、近似特征向量和给定 $s>0$ 可以作为精确 dyadic 数据。浮点求根、场方程、通量最小化、QR、Vandermonde插值只负责选取这些数。后验残差负责其精度。试探场也无须精确归一化，未归一化E、M、S处理其实际尺度。无需把这些求解过程全部改成区间线性求解。

**qj 场必须重建共享关系。** 原始节点拓扑共享可以保留；上下从属值须由同一主节点乘精确 $e^{\mathrm i/2}$ 得到。27胞公共墙只定义一次。尤其不能将 `direct_pipeline.m:569` 的逐单元浮点单项式系数当作独立函数定义：即使原节点共享，独立浮点多项式转换也没有给出严格边连续性。用精确有理 Lagrange 转换从主节点生成局部多项式，再在球中评价。

**整数 RT3 基的边界。** 整数系数参考基使参考边法向迹恒等式和内部零迹精确；任意 dyadic 内部系数仍有零法向迹。它不使 rounded phase 等于精确相位，也不使 `B*local_coefficients` 的浮点缓存保留精确抵消。应导出整数基中的内部系数及唯一全局边主矩，再用整数方向、精确相位及同一Piola几何展开。外墙主矩保持精确0。这个修复同时用于qj与C。

**几何不能混用两种定义。** 冻结曲线节点给出的是 dyadic 曲边网格；重新计算真弧后，旧二次边不再自动等于该真弧的二次插值。当前薄层和拟合图公式恰依赖后一个等式。推荐导出角度的整数编号，所有真弧顶点/中点从规范有理模型及 Arb pi 重建；普通背景顶点可以固定为dyadic。非曲线边中点取同一端点表达式的精确平均。这样保留原证明结构，试探场只发生允许的微小变化，所有积分重算。原 `r>1e-14` 保护分支只可作为数值求值保护，不能成为真几何定义；认证图使用 $r>0$ 的公式及 $r=0$ 连续延拓。若坚持完全冻结旧网格，必须把其真实 dyadic 曲边作为同伦起点并重新证明闭合/覆盖，不能继续直接套当前 Pi2 c 余项。

**B 的固定响应是可用的。** 每面板的有限 Fourier 多项式系数任意，归一相位参数和精确 Bloch 基恢复后定义合法全线响应。面板间无须导数匹配。`Xzc/XDc/XDl` 不是自由试探数据，它们是物理乘子的派生缓存，须复算或附严格乘积误差。

**C 的无限链不能冻结所有派生块。** P可作为任意固定dyadic传递矩阵，但须验证某个有限幂收缩。U的边界行按同一I/P构造；低Fourier映射G用精确指数。只冻结内部场数据和一个通量主墙映射 $N_b$，由同一公式构造 $F_b=N_bP$、$N_0=N_bG$。若将这三个乘积独立浮点冻结，原本的全链H1/H(div)匹配不再严格。端口修正须针对重建后的实际FE迹重新定义；两项使用同一表达式才能逐点相消所有额外Fourier分量。

**D 的代表函数与能量基。** r必须是精确 $\kappa_k=\sqrt{\beta_k^2+1}$ 的解析函数；冻结一个近似kappa将破坏Riesz代表恒等式，补空间保留迹不再严格为0。浮点P可冻结为可逆dyadic基变换，空间仍含所有精确代表函数；但此时真实H通常不等于I。推荐在Arb中重算 $H=P^*H_{raw}P$，把H-I加入组装误差。另一个正确方案是以精确解析Cholesky定义P并球包围其系数。当前仅有 $\|H-I\|_1=5.04\times10^{-14}$ 的浮点检查，两种方案均需补上严格界。

**模型参数与自由数据分开。** $s$可选为原double；模型常量不是任意可选数据。统一 $\alpha_-=1089/625$、$\alpha_+=56169/10000$、$\beta_0=1/2$、$a=3/25,1/5$、星形系数 $1/5,3/10,3/2$、带边 $659/500,19/8$。`arb(float(pi))` 精确得到浮点pi，而非真pi；这里应使用 Arb 的 pi。两者的区别不能靠“double→Arb精确”消除。

**显示端点也需要有向舍入。** `qj-cert-v2/output/run-004/analysis.json` 的 `scalar_decimal` 给出未计舍入的高精度中心端点。常用简写 `[2.4287286691978, 2.4287286736601]` 相对这些值，左端向内约8.59828e-15，右端向内约2.30420e-14。它可以描述结果，但不能照抄成严格包含区间。后续只从球的外端点定向打印；这两个差值不是上游误差的界。

## 最小余量

以下是现有记录中五类最小的严格正检验量；不同单位不能横向当作同一条件数排序。逐面板 reciprocal lower、候选驻点归属及A矩阵norm没有完整记录，所以这不是对未导出内部量的穷尽最小值宣称。

| 项目 | 已存绝对量 | 相对尺度 | 舍入影响判断 |
|---|---:|---|---|
| D近贴边shift的最小LDL枢轴 | 1.10754e-10 | 相对gamma_safe约3.03e-10；依赖基与消元顺序 | 精确保留原十位下界时最敏感；只证H可用0.36等宽shift |
| qj/C全元Jacobian下界 | 7.73167e-6 | 最小值所在仿射元det_min/det_max约1；源见QG/CG | 绝对数小主要是单元面积；需要全元界，非危险谱间隔 |
| A最小下端负方向 | 1.39722e-4 | 原169阶矩阵norm未保存 | 最小关键谱符号余量；128位复算预计足够，尚未证明 |
| B右材料下端Schur间隔 | 0.00428912961539 | 对JSON中心C/E行范数参考约0.007886 | 允许约1e-6新增误差仍有明显间隔；大Gram抵消须量化 |
| D代表函数余项Gram最小值 | 0.00496400970240 | 每个2阶块的最大值未保存 | 需严格2阶正性或验证基变换可逆；不是线性依赖的证据 |

qj 的E半宽约2e-12、M剩余精度预算约2.6e-12，比这些符号量小得多，但属于准确度预算。未计入的双精度全量求和可能吃掉它们；E1系数和总和复算是必要的。C的交叉空间重叠最小值约9.16e-14、秩亏R的浮点最小值约-4.49e-22是诊断量，不是证明C.3所需的严格正门槛，不应为了保存这些数值而把全部精度推高。

可用于实施阶段的条件预算：若A每个矩阵新增谱误差不超过1e-6，下端余量仍约1.387e-4；B若新增误差不超过1e-6，最小Schur余量仍约0.004288。若C两侧新增trace归一误差各不超过1e-5，由迹界带来的核心损失不超过 $2\coth(1)\,10^{-5}\approx2.63\times10^{-5}$。再给D本地1e-6，第二方向仍大于0.3653。这些是预算条件，不是已测到的Arb误差。qj先给新增舍入 $\epsilon_E\le2\times10^{-13}$、$\epsilon_M\le5\times10^{-13}$、$\epsilon_S\le10^{-13}$，最终宽度用四角式重新决定，不预报未经计算的新端点。

## 试点

未做。清单已经完成；若剩余预算允许，仅对D导出的固定有限矩阵做E3试点，不把它称为全链的舍入认证。

## 实现计划

推荐统一模型/schema、MAT导出及Arb公共库，使用一个串行分阶段驱动；不把全部大矩阵塞进一个常驻进程。阶段之间传有向球或dyadic中心加谱半径，几何/求积/指数矩缓存共享。当前目录各自重跑完整基准会重复生成场和通量；一次生成主数据再分阶段认证更便宜。

| 顺序 | 实施内容 | 工程工时预计 | 认证运行预计 | 峰值内存目标 | 需要重新导出的MATLAB数据 |
|---|---|---|---|---|---|
| 0 | 规范有理常量、位精确I/O、相位/共享拓扑、球交接schema | 0.5–1天 | 分钟级 | <1 GiB | qj主节点、主边/内部通量、整数拓扑；不导出独立局部缓存 |
| 1 | E3公共惯性/谱界引擎与D固定矩阵基准 | 0.5–1天 | 试点Arb 2.07秒；含监控17.55秒 | 实测1.24 GiB | D最终矩阵、近似向量/因子；仅用于校准 |
| 2 | A的材料矩、118面板覆盖、472个有限符号 | 0.5–1天 | 5–30分钟 | 0.5–1.5 GiB | 新入口导出逐面板近似向量/因子与norm；现A无结果JSON |
| 3 | qj精确可容许数据、二维模型、逆图、E/M/S及四角/I1 | 2–3天 | 1–6小时，按模板/面板分块 | 1–2.8 GiB | 重生P3与RT3一次；旧进程不保留场/通量，必须重跑 |
| 4 | B固定多项式响应、真实曲线源与Poisson Gram | 1.5–3天 | 必要两下端合计3–12小时；四端可到6–24小时 | 1–2.8 GiB | N26、21源、6系数、64面板；每面板约5.7MB复系数，逐块导出 |
| 5 | C精确墙约束、几何与残差Gram、无穷尾和下DtN | 1.5–2.5天 | 两侧1–6小时；是另一主要成本待测点 | 1–2.8 GiB | U的独立内部行、P、通量主墙与内部系数；按元素块约10MB导出 |
| 6 | D真解析M1/代表/B、星形矩、重新组装及验证惯性 | 0.5–1天 | 5–30分钟 | 1–2.5 GiB | 原代码重生约14秒；浮点P只作预条件，其余矩必须球复算 |
| 7 | 全链接线、回归、外端点打印和报告 | 0.5天 | 分钟级加一遍全链 | <2.8 GiB | 最小输入证书与方向明确的结果 |

工程合计约7.5–13天；首个完整球复算预计6–25小时，不含回退重试。除E3有限矩阵试点外，上述运行估计只以已有浮点成本与微型Arb调用作量级规划，尚未对B/C的主产品标定。首次实现先测一个qj界面面板、一个B相位面板、一个C元素块；外推若超过单run30分钟或3 GiB，必须按同一结果分块，并保留整个结果的累计成本，不能重置预算。

B的证明主路线还可省掉非必要上端计算：两材料在alpha_-的Schur严格正，结合A与已证单调性，已给出到上带边之前的半引线无谱及K+=279.9。原四端与B3响应Gram仍可保留为浮点诊断；若也要把这些附加数值标为已认证，另做表中相应E1/E3，不把它们混进最短主链。

性能安排：A/B/D的指数矩按频率合并缓存；B的X是二维Toeplitz，可用python-flint本包的acb_poly卷积或严格包围的分块乘法，避免每相位复制2809阶球矩阵。C先用精确有理多项式矩处理仿射类，再处理少量曲边/解析修正。qj逆多项式和预条件器可从浮点导出作为任意猜测，只在球中验证最终缺陷，省掉重做全部猜测迭代。Arb矩阵norm优先用Frobenius/1范数与无穷范数的严格上界，避免为非关键norm逐个求谱。

E2只作后备：标准gamma_n需要明确的舍入模式、运算路径与无下溢前提；复杂BLAS、FMA、并行sum和传递幂的极小数均未记录这些条件。即便用E2，也须在Arb中评价其误差上界，并将可能下溢的块交回E1或另证绝对下溢项。默认球算术路径更容易逐项核查。

## 未决问题

1. 旧MAT没有保存，必须新增导出入口；本阶段没有改动任何数值实现。可容许对象应由主数据与结构关系定义，不能把全部缓存直接保存后当作定义。
2. A无既存逐面板JSON/norm；qj未保存每个reciprocal lower及所有候选点分支余量，D未保存各2阶Gram的相对条件数。这些输出须在后续入口加入，当前无法保证上面五项是所有内部量的绝对最小值。
3. B/C的球产品主成本仍未测量，性能估计范围宽。128位用于A/D线性代数起步，qj/B/C从192位起步，必要时局部256位；精度选择须由球半径是否满足预算决定。
4. 一阶交集I1也需使用同一批球E/M/S重新包围。若只认证H计数而不补这个存在性输入，Theorem S.2仍不是完整的舍入结论。
5. BIE参考、旧FE根/计数、Q16/Q24包含检查、C的极小重叠特征值及D附加随机场相对检查都是诊断。它们保留当前状态；证明使用显式包围和严格有限测试。最终链无需Bessel/Hankel，故本计划不为参考BIE另造球算法。
6. 当前表没有给任何未经复算的最终球端点。12个四角符号、模型可容许性、A/P、下DtN和最终核心惯性必须在同一规范模型下全部通过，才可取消“舍入排除”。
'''
pilot_path=here/'run-003/science/pilot-certificate.json'
if pilot_path.exists():
 pilot=json.loads(pilot_path.read_text());mon=json.loads((here/'run-003/monitor.json').read_text());export=json.loads((here/'run-002/science/pilot-export.json').read_text())
 paragraph=r"""已做，成功。复制 h-core-v1 到 probe 内，进程内重生 $(31,16)$ 的最终浮点矩阵，第二特征值相对原记录差小于 $10^{-12}$。`-v7` 文件为14,710,348字节，保存固定 $L_{cert}$ 的实部、虚部最大条目界、近似负向量及实Cholesky见证。probe共用量保持在20MB以内。

采用128位、11线程Arb：对 $T=\Re L$ 验证 $T-\gamma I+8vv^T\succ0$，$\gamma=36537/100000$，再计入完整虚部的范数界。没有依赖浮点LDL枢轴符号。结果为
$$n(L_{\mathrm{frozen}})=1,\qquad \lambda_2(L_{\mathrm{frozen}})\ge\frac{36536998}{100000000}=0.36536998.$$

| 量 | 严格验证结果或监控实测 |
|---|---|
| 因子残差Frobenius上界 | $3.711\times10^{-15}$ 以下 |
| 三角比较逆无穷/1范数上界 | 2260.444 / 1481.537 以下 |
| 残差乘逆范数条件 | $1.243\times10^{-8}<1$ |
| 秩1修正矩阵的正下界 | 大于 $2.9860\times10^{-7}$ |
| 完整虚部算子界 | 小于 $1.5710\times10^{-8}$ |
| 负向量Rayleigh上界 | 小于 -6.4171358886 |
| Arb纯验证时间 / 其中矩阵乘法 | 2.07482秒 / 0.65733秒 |
| 含受监控MATLAB父进程的墙时 / 峰值 | 17.54846秒 / 1.24450 GiB以内 |

上表十进制上/下界均比球输出向外放宽。机器记录：[pilot-certificate.json](../../../test/numerical-directions/rounding-v1/probe/run-003/science/pilot-certificate.json)；[monitor.json](../../../test/numerical-directions/rounding-v1/probe/run-003/monitor.json)。递推与秩1推导在 [probe/README.md](../../../test/numerical-directions/rounding-v1/probe/README.md)。

这个结论只覆盖**固定导出double矩阵及其虚部包围**。该矩阵的上游H、材料积分、DtN输入和epsilon仍按原浮点方式产生，故这不是完整(D)或(H)的舍入认证。它表明E3的有限矩阵部分很便宜；B/C的源项与残差积分尚需单独标定。复现：

```sh
python3 test/numerical-directions/rounding-v1/probe/pilot_launch.py --mode export --output test/numerical-directions/rounding-v1/probe/run-002 --left test/numerical-directions/h-dtn-v1/left-certificate.json --right test/numerical-directions/h-dtn-v1/right-certificate.json
python3 test/numerical-directions/rounding-v1/probe/pilot_launch.py --mode proof --output test/numerical-directions/rounding-v1/probe/run-003 --mat test/numerical-directions/rounding-v1/probe/run-002/science/pilot.mat
```

重跑须用新编号。Python由受监控MATLAB的system子进程启动，整个树都受3 GiB和时间上限约束。"""
 text=text.replace('未做。清单已经完成；若剩余预算允许，仅对D导出的固定有限矩阵做E3试点，不把它称为全链的舍入认证。',paragraph)

(root/'research/explorations/numerical-directions/rounding-inventory.md').write_text(text)
(here/'inventory-summary.json').write_text(json.dumps({'rows_by_stage':dict(sc),'treatments':dict(tc),'total':len(rows),'all_source_lines_exist':True,'kind_coverage':{s:sorted(set(r['kind'] for r in rows if r['stage']==s)) for s in sc}},ensure_ascii=False,indent=2)+'\n')
print('written',len(rows),'rows',dict(sc),dict(tc))
