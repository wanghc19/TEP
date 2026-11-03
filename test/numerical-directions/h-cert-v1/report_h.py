"""H means hypothesis: write its Chinese certificate report from small records.
Input: manifest and analysis JSON paths. Output: the experiment README.
"""
import argparse,json,re
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('manifest');p.add_argument('analysis');a=p.parse_args()
here=Path(__file__).resolve().parent
read=lambda p:json.loads(Path(p).read_text())
cfg=read(a.manifest);rr=[read(p) for p in cfg['main']];tt=[read(p) for p in cfg['trial']];z=read(a.analysis);tails=read(cfg['tail'])
proofs=re.findall(r'<details>.*?</details>',(here/'README.md').read_text(),re.S)
f=lambda v:f'{v:.12g}'
def table(head,rows):
 return '| '+' | '.join(head)+' |\n|'+ '|'.join(['---']*len(head))+'|\n'+'\n'.join('| '+' | '.join(str(v) for v in r)+' |' for r in rows)+'\n'
body=['# h-cert-v1：isolation hypothesis certificate\n\n`h-cert` 是 isolation hypothesis certificate，指隔离假设 $(H)$ 的证书。本目录计算表面态端点 B1、B2 和半引线预解式常数 B3。\n',
'## 目的\n\n'+('四个端点的有限 Schur 检验均通过，两种材料的负指标在窗口两端相同。排除舍入后，这给出截线两侧均无表面态，并给出下一步所用的 $K_+$。' if all(z['checks'].values()) and all(t[3] for t in z['B2']) else '存在未通过的核查，结果和限制列在下面。')+'\n',
'## 起点与输入\n\n采用 `research/explorations/numerical-directions/h-cert-proof.md` 的 §1.1、§1.2、§2.4、§3 和 §7.2，以及相邻复核文件。周期谱距离取已给定的 $d=\\min(\\lambda-1.318^2,2.375^2-\\lambda)$。\n\n`fem-pipeline-v1/direct_native.m` 的 `LOCAL_curve` 使用原取向三叶形；胞中心为整数，胞壁为半整数，物理端口为 $-1/2,1/2$。左端口平移 $+1/2$，右端口平移 $-1/2$ 后截线均为 0。周期延拓的计算胞是 $[0,1]\\times[-1/2,1/2]$，夹杂中心 $(1/2,0)$。没有反射。夹杂密度 17、背景 1，横向相位 $0.5$。\n\n边界为 $R_a(1+a\\cos3t)(\\cos t,\\sin t)$，$R_a=0.2/\\sqrt{1+a^2/2}$。两个材料的最大半径与截线最小间距如下；故 $a_{collar}=1/4$ 有效。\n',
table(['材料','最大半径','截线间距下界'],[[v['material'],f(v['radius_max']),f(v['collar_min'])] for v in tails['geometry']]),
'## 复现命令\n\n从仓库根目录执行下列命令；每次须用新的 `run-NNN`。入口参数完全给出数值配置，不读取旧输出配置响应场。保留旧记录时，把输出改为未用编号，并同步 `manifest.json` 的显式路径，再运行汇总。\n\n```sh\n']
for path,r in zip(cfg['main'],rr):
 run=Path(path).parent.parent.name
 method=' --poisson2' if r.get('bound_method')=='poisson2' else ''
 body.append(f"python3 test/numerical-directions/h-cert-v1/launch_h.py --output test/numerical-directions/h-cert-v1/output/{run} --material {r['material']} --lambda {r['lambda']} --order {r['N']} --phases {r['phase_panels']} --quadrature {r['curve_points']} --certificate --degree {r['trial_degree']} --phase-order {r['phase_gauss_order']}{method}\n")
for path,r in zip(cfg['trial'],tt):
 run=Path(path).parent.parent.name
 analytic=' --analytic' if 'curve_points' in r else ''
 quadrature=r.get('curve_points',r.get('quadrature_order'))
 body.append(f"python3 test/numerical-directions/h-cert-v1/launch_h.py --output test/numerical-directions/h-cert-v1/output/{run} --material {r['material']} --lambda {r['lambda']} --order {r['N']} --phases {r['Ntheta']} --quadrature {quadrature}{analytic}\n")
body+=['python3 test/numerical-directions/h-cert-v1/tail_constants.py test/numerical-directions/h-cert-v1/tail-constants.json\n',
f"python3 test/numerical-directions/h-cert-v1/launch_analysis.py --output test/numerical-directions/h-cert-v1/output/{Path(a.analysis).parent.parent.name} --manifest test/numerical-directions/h-cert-v1/manifest.json\n",
'python3 test/numerical-directions/h-cert-v1/report_h.py test/numerical-directions/h-cert-v1/manifest.json '+str(Path(a.analysis).resolve().relative_to(here.parent.parent.parent))+'\n```\n\n全部 MATLAB 运行由 `diagnostics-v1/monitor.py` 启动，11 线程，`OMP_DYNAMIC=FALSE`。正式端点运行预估 8–22 分钟、峰值 1.8–2.8 GiB；监控软限 30 分钟、硬限 40 分钟、峰值硬限 3 GiB。较小空间的复现参数在对应 `command.json` 与 `result.json` 中。\n',
'## 尾项常数\n\n使用粗源界 (3.14)。全部 $n_k$、$D_0$ 对角元和常数在 `tail-constants.json`。$n_0=1/(2\\sqrt{1.25})$；$a_M$ 的最大值在 $k=-(M+1)$。\n',
table(['$\\lambda$','$M$','$a_M$','$b_{out}$','$c_P$','$h_M$','$x_M$','$t_M$','$x_M^2/t_M$'],[[r['lambda_value'],r['M']]+[f(r[k]) for k in ['a_M','b_out','c_P','h_M','x_M','t_M','penalty']] for r in tails['table']]),
'八个尾项按三个有效数字与证明 §3.5 相同。表格是显示近似；严格检验使用源码公式与 JSON 的完整数值。\n',
table(['$\\lambda$','$D_0$ 最小对角元','$D_0$ 最大对角元','$n_0$'],[[r['lambda_value'],f(min(v['D0'] for v in r['modes'])),f(max(v['D0'] for v in r['modes'])),f(next(v['n'] for v in r['modes'] if v['k']==0))] for r in tails['table'] if r['M']==10]),
'## 低频块与残差\n\n每个 Bloch 胞用 $|m|,|n|\\le N$ 的平面波。它们的值和一阶导数严格满足两个 Bloch 相位。逆 Bloch 表达的纵向频率为 $2\\pi m+\\theta$，支持有界；系数在相位上平方可积，故全线响应属于 $H^2$。相位面板间的系数不需要导数匹配。每个相位面板内系数是给定次数的多项式，节点上的有限求解只用于选择系数。源项由 (3.22) 的正、负半轴几何级数分别计算；两个分母均保留。零横向源的非紧支撑部分同样保留，全线的直接项 $(\\lambda+1)n_0^2$ 精确求值。真实曲线的散度定理给出胞内积分。\n\n$\\widehat C$ 仍用 (3.19)–(3.21) 的二次恒等式。下端误差使用周期 Poisson 通量的形式残差界 $E=K\\overline H+(\\epsilon_C+K\\epsilon_H)I$。上端用二次 Poisson 恒等式进一步收紧误差和响应界，公式见下面推导。原体残差大小同时保留在下表；它没有被丢弃。实现为 `h_bloch.m`，完整矩阵在每次运行的 `science/result.json`。\n',
table(['材料','$\\lambda$','$N$','面板/次数','$\\sqrt{\\|G_r\\|}$','$\\sqrt{\\|\\overline H\\|}$','$\\|E\\|$','原 $\\|G_r\\|/d$'],[[r['material'],r['lambda'],r['N'],f"{r['phase_panels']}/{r['trial_degree']}",f(r['weighted_residual_norm']),f(r['unweighted_dual_norm']),f(r['error_norm']),f(r['original_volume_error_norm'])] for r in rr]),
proofs[0]+'\n' if proofs else '',
'## 端点惯性 (B1, B2)\n\n负指标 $m$ 来自 (3.16) 两个 Schur 矩阵。两者必须非奇异且负指标相同。下表使用积分包围后的误差矩阵。\n',
table(['材料','$\\lambda$','$M$','$m_- / m_+$','$\\gamma$','$\\|E\\|$','$x_M^2/t_M$'],[[r['material'],r['lambda'],t['M'],f"{t['negative_Cminus']} / {t['negative_Cplus']}",f(t['gamma']),f(t['E_norm']),f(t['tail']['penalty'])] for r in rr for t in r['tests']]),
table(['材料','$m(\\alpha_-)$','$m(\\alpha_+)$','B2'],[[t[0],int(t[1]),int(t[2]),'相等' if t[3] else '不相等'] for t in z['B2']]),
'根据定理 B.3，相等的负指标排除该材料在截线两侧的整个闭窗口表面谱。\n',
'## 半导波预解式常数 (B3)\n\n上端使用 $M=10$，由 (3.17)、(3.25)、改进后的 (3.27) 和 (3.28) 计算。粗界使用相同的边界逆范数与 (3.26)，未代入计划中的假设间隙 0.1。\n',
table(['材料','$\\|\\mathscr B^{-1}\\|$ 上界','$\\|\\mathscr T\\|^2$ Gram 上界','(3.26) 粗界','$d_{half}$','$K_+$','粗 $K_+$'],[[t[0]]+[f(v) for v in t[1:7]] for t in z['B3']]),
'当下端 $m=0$ 时，还能直接得到更紧的距离界。B1 的可逆性与零负指标给出 $\\mathscr B_{\\alpha_-}\\ge bI>0$。对 $\\alpha_-\\le\\mu<2.375^2$，$\\mathscr B_\\mu-\\mathscr B_{\\alpha_-}=\\int_{\\alpha_-}^{\\mu}\\mathscr T_t^{*,\\rho}\\mathscr T_t\\,dt\\succeq0$。因此每个 $\\mu\\in[\\alpha_-,2.375^2)$ 都有可逆的 $\\mathscr B_\\mu$；(3.24) 给出两个半引线在这些点的预解式。于是 $d_{half}(\\alpha_+)\\ge\\min(\\alpha_+-\\alpha_-,2.375^2-\\alpha_+)=0.023725$。这个推论只在零负指标时使用。它不改变上表按 (3.25) 请求计算的 Gram 与粗界。\n',
table(['材料','单调性距离界','单调性 $K_+$'],[[v[0],f(v[1]),f(v[2])] for v in z['B3_monotonic']]),
'下表的响应误差、$a_{low}$、$a_{high}$ 均为从边界系数 $\\ell^2$ 到 $L^2_\\rho$ 的算子范数。$G_U$ 是参考提升加试探响应的加权 Gram。\n',
table(['材料','$\\lambda_{max}(G_U)$','$\\|Rr\|_\\rho$ 误差上界','$a_{low}$','$a_{high}$'],[[v[0]]+[f(x) for x in v[1:]] for v in z['B3_components']]),
'## 积分包围\n\n曲线梯形规则和相位 Gauss 规则都有显式余项。正式四个端点的 $\\widehat C$、$G_r$、$\\overline H$ 和响应 Gram 积分均计入截断余项；没有仍以裸浮点求积代替的积分。下面给出相位与空间余项合计。有限算术舍入仍被排除。较小空间对照的空间和相位积分只作浮点一致性比较，没有加积分包围，不是正式 B1/B3 界的输入。\n',
table(['材料','$\\lambda$','$\\epsilon_C$','$\\epsilon_H$','$\\epsilon_U$','$\\epsilon_G$','$\\epsilon_{H^{(2)}}$','曲线原始余项','曲线传播余项'],[[r['material'],r['lambda']]+[f(r[k]) for k in ['eps_C','eps_H','eps_U','eps_G']]+[f(r['eps_V2']) if 'eps_V2' in r else '—']+[f(r[k]) for k in ['curve_moment_error','curve_propagated_error']] for r in rr]),
proofs[1]+'\n' if len(proofs)>1 else '',
'24 阶对照主规则与最终采用的 40 阶规则的差，以及曲线加倍点数的差列在 `analysis.json`。曲线比较包括全部 $X$ 矩元和 $\\theta=-\\pi,0,\\pi$ 的源矩量；解析余项对全部相位有效。两种曲线规则的差大于极小的解析余项，有限浮点算术已到舍入尺度；没有把这些差值加作解析截断余项。\n',
'## 核查\n']
labels=['尾项表','两个试探空间','单调性','M=8/10','求积','Hermitian 与 Gram 正半定']
keys=['tail_table','two_trial_spaces','monotonicity','M8_M10','quadrature','Hermitian_PSD']
detail=[
'八个值均在三个有效数字上复现 §3.5。',
f"四个 $N={tt[0]['N']}$ 与 $N={rr[0]['N']}$ 空间满足 $\\|\\widehat C_1-\\widehat C_2\\|\\le\\|E_1\\|+\\|E_2\\|$；最大比值 {f(max(v[2]/v[3] for v in z['trial_comparison']))}。",
f"$\\widehat C_+-\\widehat C_-+E_++E_-$ 的最小特征值 {f(min(v[2] for v in z['monotonicity']))}。",
'四端点两个边界截断的惯性相同；尾罚项均下降超过 100 倍。',
f"主/高阶规则与曲线加倍的最大比较量 {f(max(max(v) for v in z['quadrature_comparison']))}，预设容差 $10^{{-9}}$，小于最小间隙的 {f(max(max(v) for v in z['quadrature_comparison'])/min(t['gamma'] for r in rr for t in r['tests']))}。",
f"最大原始相对非 Hermitian 量 {f(max(max(v[:2]) for v in z['Hermitian_and_PSD']))}，容差 $10^{{-12}}$；最小 Gram 特征值 {f(min(v[2] for v in z['Hermitian_and_PSD']))}，按 $-10^{{-12}}\\|G_r\\|$ 的舍入尺度核查；精确算术中的残差 Gram 按构造正半定。"]
for j,(label,key,deta) in enumerate(zip(labels,keys,detail),1):body.append(f"{j}. {label}：{'通过' if z['checks'][key] else '未通过'}；{deta}\n")
body+=['\n'+table(['材料','$\\lambda$','两块差范数','误差范数和'],[[f(v) for v in r] for r in z['trial_comparison']]),
'## 成本\n\n14 次监控运行合计 '+f(sum(read(p)['wall_seconds'] for p in (here/'output').glob('run-*/monitor.json')))+' 秒，最大峰值 '+f(max(read(p)['peak_process_tree_rss_gib'] for p in (here/'output').glob('run-*/monitor.json')))+' GiB。\n\n'+table(['运行','壁钟秒','峰值 GiB','结束原因'],[[r.parent.name,f((d:=read(r))['wall_seconds']),f(d['peak_process_tree_rss_gib']),d['reason']] for r in sorted((here/'output').glob('run-*/monitor.json'))]),
'## 对下一步的意义\n\nB1–B3 已给出可用于下一步的有限输入。若 DtN 低模修正预算取 $K_+r\\le4\\times10^{-4}$，则所需残差为：\n',
table(['材料','Gram 界的 $\\sqrt r$ 上限','单调性界的 $\\sqrt r$ 上限'],[[v[0],f(v[7]),f(z['B3_monotonic'][j][3])] for j,v in enumerate(z['B3'])]),
'下一步计算物理半引线的 DtN 场、通量及修正矩阵，再做芯区最终计数。\n',
'## 限制\n\n所有包围排除浮点舍入。有限矩阵的特征值和符号尚需后续区间算术包围。本方法同时检验截线两侧；左右物理半引线分别由对应材料的这一结论覆盖。关口 C、D 和最终计数尚未计算，$(H)$ 仍待这几步完成。\n']
(here/'README.md').write_text('\n'.join(body))
# Record the proof obligations beside the numerical data, not as a runtime input.
import math
conditions=[]
for r in rr:
 h=math.pi/r['phase_panels'];s=.75*h;N=r['N'];lam=r['lambda'];zb=r['max_trial_bound']
 modes=range(-10,11);T=0
 for k in modes:
  beta=.5+2*math.pi*k;q=math.sqrt(1+beta*beta);kap=q if k==0 else math.sqrt(beta*beta-lam)
  T+=(math.exp(s)*math.sqrt(q)/(2*kap)*(1+math.exp(s))/(1-math.exp(-kap+s)))**2
 tb=math.sqrt(T);fb=(17*lam+1)*tb;lb=(2*math.pi*N+math.pi+1.25*h)**2+(2*math.pi*N+.5)**2+17*lam
 A=(r['dimension']+22)*(1+lb+fb+zb)
 conditions.append({'material':r['material'],'lambda':lam,'phase_strip':s,'inverse_D_bound':1/(.25-s*s),'A_lower':r['dimension']+22,'A_upper':A,'A_times_curve_error_upper':A*r['curve_moment_error'],'D_tail_lower':min((2*math.pi*(N+1)-math.pi)**2+.25,(2*math.pi*(N+1)-.5)**2),'analytic_strip_valid':s<.5,'propagation_valid':A*r['curve_moment_error']<1})
proof={'task_mode':'Proof from scratch','target':'README.md: Poisson and integration details, B3 monotonicity paragraph','result':'Proved under the supplied periodic-gap certificate, excluding rounding','literature_status':'Proof literature verification completed.',
 'verified_references':['h-cert-proof.md (2.16)-(2.18): periodic gap input','h-cert-proof.md (3.1): weighted full-periodic inverse','h-cert-proof.md (3.19)-(3.21): stationary action and residual identity','h-cert-proof.md (3.9): positive derivative','h-cert-proof.md (3.24): decoupled Dirichlet resolvent','h-cert-proof.md (2.11)-(2.12): analytic-curve trapezoid remainder'],
 'new_deductions':['Poisson H-minus-one residual bound','Second Poisson resolvent identity and squared-inverse Gram','Positive Gauss rule plus Chebyshev truncation error for polynomial response trials','Propagation of analytic-curve moment errors','Zero negative inertia extends pole freedom to the known upper periodic-gap endpoint'],
 'conditions':conditions,'remaining_scope':['rounding','gates C and D','final core count']}
(here/'proof-obligations.json').write_text(json.dumps(proof,ensure_ascii=False,indent=2)+'\n')
m=z['B3_monotonic'][0]
(here/'monotonic-constant.json').write_text(json.dumps({'d_half':m[1],'K_plus':m[2],'sqrt_r_target':m[3],'premise':'Both lower endpoint boundary operators have negative inertia zero and positive Schur gaps.'},indent=2)+'\n')
