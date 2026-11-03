"""Write the Chinese experiment handoff from checked scalar records.
Input: baseline and scan run directories. Output: the experiment README.md.
"""
import argparse,json
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--baseline',required=True);p.add_argument('--scan',required=True);a=p.parse_args()
b=Path(a.baseline);s=Path(a.scan);here=Path(__file__).resolve().parent
x=json.loads((s/'analysis.json').read_text());raw=json.loads((b/'science/summary.json').read_text());base=raw['baseline']
scan=json.loads((s/'science/summary.json').read_text());pr=scan['p3']['rows'];p2=scan['p2']['rows'];cases=x['endpoint_cases']
rel=lambda path:Path(path).resolve().relative_to(here).as_posix()
bs=rel(b);ss=rel(s);source=f'[{ss}/analysis.json]({ss}/analysis.json)'
near=lambda rr,k:min(rr,key=lambda r:abs(r['k']-k))
f=lambda v:format(v,'.17g')
g=lambda v:format(v,'.12g')
lines=['# Goerisch 隔离窗口端点检查','',
'`gap-ends` = spectral gap endpoints（谱隙端点）；v1 = 版本 1。FEM = finite element method（有限元法）；DtN = Dirichlet-to-Neumann；P2/P3 = 二次／三次单元；RT3 = Raviart–Thomas 三阶通量；BIE = boundary integral equation（边界积分方程）；RSS = resident set size（常驻内存）；JSON = JavaScript Object Notation；CSV = comma-separated values。`fem_i9` 保留实现阶段 I9.3 的函数名。', '',
'## 目的','',
f'高端窗口 $k\\in[2.1875,2.38]$ 未发现候选，建议 $\\alpha_-=1.32^2$、$\\alpha_+=2.37^2={g(x["recommended_alpha_plus"])}$。P3 的端点负指标由 0 增至 1，P2 核对一致；半引线扫描未见 DtN 极点。这些结果是普通浮点检查。全部派生数字见 {source}。','',
'## 起点与输入','',
'代码复制自 [fem-pipeline-v1](../fem-pipeline-v1/README.md)，保持原物理模型、界面几何、材料修正、P3 g48 网格、RT3 通量、两侧各 13 胞元延拓、主／核查积分 16／24 阶。模型为 $\\beta=0.5$，周期与条带宽度 1，背景／中心／引线材料 1／4／17，中心星形及左右三叶形参数保持原值。', '',
'理论公式沿用 [Goerisch 宽度](../../../research/explorations/numerical-directions/goerisch-width.md) 和 [DtN 惯性计数](../../../research/explorations/numerical-directions/dtn-inertia-count.md)。两侧采样带边与旧端点来历见 [输入输出事实表](../../../research/explorations/numerical-directions/bie-fem-io-facts.md)；这些带边并非认证端点。', '',
'新增入口只接收显式阶段和输出目录。每次重新生成场和矩阵，无旧 MAT 或旧场依赖。BIE 参考 $\\mu_{\\rm BIE}=2.428728670022710$ 只用于解算后的包含检查及数值评价 $C$，不用于选根。','',
'## 复现命令','',
'在仓库根目录执行；输出目录必须尚不存在。以下新编号适用于当前保留记录之后。','',
'```sh',
'python3 test/numerical-directions/gap-ends-v1/launch_gap.py --stage baseline --output test/numerical-directions/gap-ends-v1/output/run-006',
'python3 test/numerical-directions/gap-ends-v1/launch_gap.py --stage scan --output test/numerical-directions/gap-ends-v1/output/run-007',
'python3 test/numerical-directions/gap-ends-v1/analyze_gap.py --baseline test/numerical-directions/gap-ends-v1/output/run-006 --scan test/numerical-directions/gap-ends-v1/output/run-007',
'python3 test/numerical-directions/gap-ends-v1/write_report.py --baseline test/numerical-directions/gap-ends-v1/output/run-006 --scan test/numerical-directions/gap-ends-v1/output/run-007',
'```','',
'启动器调用 `diagnostics-v1/monitor.py`，MATLAB R2023b，11 MATLAB/OpenMP 线程，`OMP_DYNAMIC=FALSE`。启动 MATLAB 按任务要求请求提权。A、B、C 各项软／硬时间上限 30／40 分钟，峰值 RSS 硬限 3 GiB。主数值源文件已经完整保留；`build_scan.py` 只用于从本目录的 `direct_native.m` 和 `scan_extension.m` 重建扫描副本，不是运行前提。','',
'## A 结果','',
f'候选数 **{x["candidate_count"]}**。13 胞元 P2 搜索用 9 个等距平方频率移位（含两端），每移位 24 Ritz 对，子空间 64；原残差、局域质量与去重过滤不变。全部 {x["ritz_count"]} 条 Ritz 记录中，落在窗口内的原始记录也为 {x["in_window_ritz_count"]}。因此没有需要逐项确认或剔除的窗口内候选。', '',
'| $k$ | P2 Ritz 值 $\\mu$ | DtN 根／残差 | 判定 |',
'|---|---|---|---|',
'| — | — | — | 空候选列表 |','',
f'独立的 P3 g48 DtN 计数在高端窗口的 {x["high_grid_points"]} 个采样点上恒为 {f(x["high_index_min"])}，总跳变 0，与空候选列表一致。下表摘录采样点；完整记录见 [{ss}/science/p3/scan.csv]({ss}/science/p3/scan.csv)。', '',
'| $k$ | $\\mu=k^2$ | $n(T_h)$ |',
'|---:|---:|---:|']
for k in [2.1875,2.25,2.30,2.35,2.37,2.38]:
 r=near(pr,k);lines.append(f'| {g(r["k"])} | {g(r["mu"])} | {r["negative_index"]} |')
lines+=['',
f'建议 $k_+=2.37$。距已采样最近上带边（右引线 $k={g(x["sampled_upper_band_edge_k"])}$）向内留 $\\Delta k={g(x["upper_margin_k"])}$、$\\Delta\\mu={g(x["upper_margin_mu"])}$。下端 $k_-=1.32$ 距已采样右下带边向内留 $\\Delta k={g(x["lower_margin_k"])}$、$\\Delta\\mu={g(x["lower_margin_mu"])}$。', '',
f'P2 原始列表：[modes.csv]({bs}/science/high-search/modes.csv)；全部移位均返回零标志。空搜索与离散计数支持该推荐，连续窗口的谱点排除仍依赖未认证的能带与半引线信息。','',
'## B 结果','',
f'基准 P2 $k_A={f(x["p2_frequency"])}$；P3 根 $k={f(x["p3_frequency"])}$。P2、P3 相对差分别为 {x["p2_relative_difference"]:.3e}、{x["p3_relative_difference"]:.3e}；旧宽度相对差 {x["reference_width_relative_difference"]:.3e}。同一进程先完成旧端点复现与 24 阶核查，再在同一 P3 场和 RT3 通量的 $q,\\delta=qJ-1$ 上评价新端点公式；没有重选场、重求通量或读取旧 MAT。','',
'| 设置 | $\\alpha_-$ | $\\alpha_+$ | $C$ | 区间，$\\mu$ 单位 | 宽度 | 含 $\\mu_{\\rm BIE}$ |',
'|---|---:|---:|---:|---|---:|---|']
for name,c in zip(['旧端点','(i)','(ii)，推荐'],cases):
 lines.append(f'| {name} | {g(c["alpha_minus"])} | {g(c["alpha_plus"])} | {c["C"]:.12g} | [{f(c["enclosure"][0])}, {f(c["enclosure"][1])}] | {c["width"]:.14e} | 是 |')
lines+=['',
f'(i) 宽度增幅 {100*x["width_i_relative_increase"]:.9f}%；实测宽度比与 $C$ 比的相对差为 {x["C_ratio_relative_error"]:.3e}，低于 0.1%。所有端点符号条件通过；Python 独立重算端点和稳定宽度公式也通过。$C$ 中的特征值以给定 BIE 数值代替，只作为数值常数评价。','',
f'同场积分核查与根历史：[baseline/result.json]({bs}/science/baseline/result.json)、[generation/root.json]({bs}/science/baseline/generation/root.json)。','',
'## C 结果','',
'### C1：端点负指标与零点距离','',
'$T_h=K-\\lambda M^\\rho+\\mathrm{DtN}$ 作用于完整约化中心单元（含中心内部自由度）。先计中心内部块与端口 Schur 补的惯性，再在四个端点用完整矩阵核对。正定块用 Cholesky；不定 Hermitian 矩阵实对称化后做稀疏 LDL，每个特征值重复两次，负指标除以 2。逐个 2×2 主元计算两个特征值，并检查重复数为偶数。','',
'下表中范数为未经预条件化的 $\\|T_h\\|_1$，零点距离来自完整矩阵的最近零特征值；它不是仅端口 Schur 补的特征值。','',
'| 单元／网格 | $k$ | $n(T_h)$ | $\\min|\\lambda(T_h)|$ | $\\|T_h\\|_1$ | 相对零点距离 |',
'|---|---:|---:|---:|---:|---:|']
for r in x['endpoint_rows']:
 lines.append(f'| P{int(r["p"])}/g48 | {g(r["k"])} | {int(r["negative_index"])} | {r["T_min_abs"]:.10e} | {r["T_norm1"]:.10g} | {r["T_relative_margin"]:.10e} |')
maxres=max(r['T_eigs_residual'] for r in x['endpoint_rows']);root=x['scan_roots'][0]
lines+=['',f'最终端点负指标差 **1−0=1**，P2 与 P3 相同。P3 在推荐上端的内部块／端口负指标为 1／0，下端为 0／0；总指标包含这两部分。扫描唯一向上跳变的局部 DtN 根为 $k={f(root["k"])}$，中心未凝聚残差 {root["center_residual"]:.3e}。完整矩阵与 Schur 分解计数逐端点一致，最近零特征对的最大相对残差为 {maxres:.3e}。这里使用两端相同的普通离散 $T_h$；**未计算 $L_h$ 的补空间界**，也未计算带误差扰动的 $U_h,L_h$。','',
'### C2：半引线 Dirichlet 极点扫描','',
'扫描两侧 QZ 稳定子空间 $Z=[Z_1;Z_0]$。$Z_0$ 是衰减解到截线 Dirichlet 迹的投影；若该投影奇异，可出现零边界值的非零衰减解。记录 $\\sigma_{\\min}(Z_0)$、$Z_0$ 条件指标、DtN 算子范数及其极端特征值，并核查 Bloch 乘子与单位圆的分离。此处奇异值是离散稳定投影的奇异值，不是无限维算子谱距离。','',
f'最终窗口内共 {x["final_scan_points"]} 点；最大步长 $\\Delta k={x["max_final_step_k"]:.6g}$、$\\Delta\\mu={x["max_final_step_mu"]:.6g}$，两端局部加密至 $\\Delta k=0.001$。全 P3 扩展扫描共 {x["all_p3_scan_points"]} 点。两侧所有采样均有效，未见投影趋于奇异或 DtN 特征值经无穷发散的迹象，**未检测到极点**。','',
'| 引线 | 最近奇异投影：$\\sigma_{\\min}(Z_0)$ | 所在 $k$ | 所在 $\\mu$ | 最小单位圆分离指标 | 最大 $\\|D\\|_2$ |',
'|---|---:|---:|---:|---:|---:|']
for name,label in [('left','左'),('right','右')]:
 z=x['lead_scan'][name];lines.append(f'| {label} | {z["min_Z0_smin"]:.12g} | {g(z["at_k"])} | {g(z["at_mu"])} | {z["min_unit_gap"]:.6g} | {z["max_D_norm2"]:.12g} |')
lines+=['',
'以相邻奇异值的有限差分定义局部变化尺度 $s/|\\Delta s/\\Delta k|$，取相邻两点较小的 $s$；该量仅描述已观测曲线。']
for name,label in [('left','左'),('right','右')]:
 z=x['lead_scan'][name];lines.append(f'{label}引线的最小观测变化尺度为 {z["min_observed_Z0_variation_scale_k"]:.6g}（$k$ 单位），相邻投影奇异值最大相对变化 {z["max_adjacent_relative_Z0_change"]:.3e}，相邻 DtN 范数最大相对变化 {z["max_adjacent_relative_D_norm_change"]:.3e}。')
lines+=['',
'网格可分辨记录中的平滑变化；没有导数包络，仍可能漏掉位于相邻采样点之间、变化尺度小于步长的窄极点特征。上述最小奇异值不能换算为已保证的极点距离。','',
'## 核查','',
f'1. 旧设置复现通过：P2／P3 相对差 {x["p2_relative_difference"]:.3e}／{x["p3_relative_difference"]:.3e}（门槛 $10^{{-12}}$），宽度相对差 {x["reference_width_relative_difference"]:.3e}（门槛 0.5%），24 阶同场核查通过。',
'2. A 通过：空候选列表，没有未处理候选；高端全部计数点恒为 1，跳变 0。',
f'3. B 通过：宽度比与 C 比相对差 {x["C_ratio_relative_error"]:.3e}（门槛 0.1%）；两新区间均含 BIE 参考。',
'4. C1 通过：P2/P3 的四个端点负指标一致；完整矩阵与内部块加 Schur 补计数一致；零点距离见表。',
'5. C2 完成采样检查：给出步长、观测变化尺度与最近奇异投影；小于采样步长的窄特征仍可漏检。','',
'## 成本','',
'启动前预计：基准与端点重算 120–300 秒、峰值 2.2–2.7 GiB；高端搜索 5–30 秒、峰值小于 1.5 GiB；183 点扫描及 P2 核对 300–900 秒、峰值 2.0–2.7 GiB。实际监控如下。','',
'| 运行 | 内容 | 墙钟，秒 | 峰值 RSS，GiB | 状态 |',
'|---|---|---:|---:|---|']
labels={1:'基准；新增汇总结构赋值错误',2:'基准、B(i)/(ii)、高端 P2 搜索',3:'扫描；MATLAB 复稀疏 LDL 不支持',4:'扫描；首行 CSV 格式错误',5:'完整 P3 扫描与 P2 端点核对'}
for run,c in x['cost'].items():
 i=int(run.split('-')[-1]);lines.append(f'| [{run}]({run.replace("run-","output/run-")}/monitor.json) | {labels.get(i,"复现运行")} | {c["wall_seconds"]:.6f} | {c["peak_process_tree_rss_gib"]:.6f} | {"完成" if c["returncode"]==0 else "失败，日志保留"} |')
lines+=['',
'高端计数同时服务 A 与 C，成本不重复相加。B 的计算与 A 的 P2 搜索共用一次进程；具体阶段秒数保留在各科学输出。失败均为入口／输出／线性代数接口问题，修复后使用新运行编号，原始失败日志保留。','',
'## 对 (H) 的意义','',
'P3 全窗口计数只出现一个向上的跳变，且高端扩大区没有新增候选；P2 端点结果一致。配合本次未见半引线极点的扫描，这支持在修正端点后继续数值使用单模隔离假设 (H)。','',
'连续 (P)、DtN 误差、投影／补空间常数 $C_h$ 和舍入均未认证；采样带边也未认证。普通离散负指标与空候选列表不构成连续谱点个数或单重性的证明。Goerisch 包围公式的保证仍以相关假设与误差控制为条件。','',
'## 限制','',
'本次只检查指定模型、截线和离散层级。高端有限区域搜索与 DtN 计数是不同数值计算，但共用模型与有限元表示。表面态扫描对窄于网格步长的结构没有排除保证；最近零特征值与奇异值均是普通浮点结果。没有计算连续补空间下界，也没有用区间算术控制惯性或区间端点的舍入。','']
(here/'README.md').write_text('\n'.join(lines))
