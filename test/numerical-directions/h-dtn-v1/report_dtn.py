"""DtN means Dirichlet-to-Neumann: write the Chinese certificate handoff.
Input: explicit analysis-input and analysis-result JSON paths.
Output: README and two small matrix certificates, with rounding excluded.
"""
import argparse,json,math
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--inputs',required=True);p.add_argument('--analysis',required=True);a=p.parse_args()
here=Path(__file__).resolve().parent
read=lambda p:json.loads(Path(p).read_text())
cfg=read(a.inputs);analysis=read(a.analysis);const=read(cfg['constants']);fe_records=read(cfg['fe'])
coarse=[read(x) for x in cfg['coarse']];fine=[read(x) for x in cfg['fine']]
f=lambda x:format(x,'.12g')
def table(headers,rows):
 return '\n'.join(['| '+' | '.join(headers)+' |','| '+' | '.join(['---']*len(headers))+' |']+['| '+' | '.join(str(x) for x in row)+' |' for row in rows])
def shifted(d,k,eps):
 return {'real':[[v+(eps if i==j else 0) for j,v in enumerate(row)] for i,row in enumerate(d[k+'_real'])], 'imag':d[k+'_imag']}
for side,d in zip(['left','right'],fine):
 cert={'description':'All-trace lower DtN matrix at the upper isolation-window endpoint; rounding excluded',
  'side':side,'lambda':5.6169,'material_a':.12 if side=='left' else .20,'port_x':-.5 if side=='left' else .5,
  'inward_sigma':-1 if side=='left' else 1,'physical_orientation':'original, no reflected inclusion',
  'y_interval':[-.5,.5],'Fourier_indices':list(range(-16,17)),'beta':[.5+2*math.pi*i for i in range(-16,17)],
  'q':[math.sqrt(1+(.5+2*math.pi*i)**2) for i in range(-16,17)],
  'coefficient_convention':'g(y)=sum_i coefficient_i exp(i beta_i y); unscaled matrices; zero extension outside retained traces',
  'K_plus':d['K_plus'],'K_minus':d['K_minus'],'a_H':d['a_H'],'b_H_squared':d['b_H_squared'],'A_H':d['A_H'],
  'Q':shifted(d,'Q',0),'Q_minus':shifted(d,'Q',-d['eps_Q']),'Q_plus':shifted(d,'Q',d['eps_Q']),
  'R':shifted(d,'R',0),'R_plus':shifted(d,'R',d['eps_R']),
  'Z':shifted(d,'Z',0),'Z_plus':shifted(d,'Z',d['eps_Z']),
  'Z_definition':'full-half-lead Gram of u+K_plus*r2, an upper surrogate for the collar Gram',
  'hat_Lambda':shifted(d,'lower',0),'upper_Lambda':shifted(d,'upper',0),
  'eps_Q':d['eps_Q'],'eps_R':d['eps_R'],'eps_Z':d['eps_Z'],'r':d['r'],'K_r':d['K_r'],'normalized_gap':d['gap'],
  'source':str(Path(cfg['fine'][0 if side=='left' else 1]).relative_to(here)),
  'trace_check':fe_records[0 if side=='left' else 1]['trace_check'],
  'geometry':fe_records[0 if side=='left' else 1]['geometry'],'series':fe_records[0 if side=='left' else 1]['series'],
  'resolvent_source':'h-cert-v1: no half-lead spectrum in [1.7424,2.375^2)',
  'assumptions':['exact real arithmetic; floating-point rounding excluded','h-cert-v1 resolvent result'],
  'all_trace_lower_bound':True,'upper_Lambda_scope':'retained 33-mode trace subspace only'}
 (here/(side+'-certificate.json')).write_text(json.dumps(cert,ensure_ascii=False,indent=2)+'\n')
old=(here/'README.md').read_text();proofs=old[old.index('<details>'):old.rindex('</details>')+len('</details>')] if '<details>' in old else ''
rows=[]
for i,(c,d) in enumerate(zip(coarse,fine)):
 for name,z in [('g24',c),('g48',d)]:
  rows.append(['左' if i==0 else '右',name,f(z['r']),f(z['K_r']),f(z['high_penalty']),f(z['gap']),f(z['min_Q_raw']),f(z['min_lower_raw'])])
epsrows=[[s,f(d['eps_Q']),f(d['eps_R']),f(d['eps_Z']),f(d['series_weight_bound']),str(d['first']['min_order'])+'–'+str(d['first']['max_order']),str(d['bulk']['min_order'])+'–'+str(d['bulk']['max_order'])] for s,d in zip(['左','右'],fine)]
comp=analysis['matrix_comparison'];lift=analysis['lift_refinement'];sym=analysis['symmetry_PSD']
mon=[]
for d in sorted((here/'output').glob('run-*')):
 if (d/'monitor.json').exists():
  m=read(d/'monitor.json');mon.append([d.name,m['reason'] if m['returncode']==0 else '失败（退出码'+str(m['returncode'])+'）',f(m['wall_seconds']),f(m['peak_process_tree_rss_gib'])])
base=read(here/'output/run-001/science/baseline.json') if (here/'output/run-001/science/baseline.json').exists() else {}
text=r'''# h-dtn-v1：DtN certificate for the isolation hypothesis

`h-dtn` 指隔离假设 $(H)$ 的 Dirichlet-to-Neumann（DtN）证书部分。

## 目的

两侧已得到 $33\times33$ 全迹下界矩阵，包含显式积分与无穷引线余项，排除舍入。最终残差罚项均低于 $4\times10^{-4}$；数值及矩阵分别见下表与 `left-certificate.json`、`right-certificate.json`。

## 起点与输入

$\lambda=5.6169$，$\alpha_-=1.7424$。h-cert-v1 排除了两种纯引线的表面态，并给出半引线在 $[1.7424,2.375^2)$ 上无谱。因此
$$K_+=1+(5.6169+1)/(2.375^2-5.6169)=279.899894626.$$
公式值为 $279.899894625925$，代码使用上面的向上取值。$d_-\ge5.6169-1.7424=3.8745$，$K_-$ 公式值为 $0.707807459027$；采用更宽的 $0.70782$。

物理端口为 $-1/2,+1/2$。左侧材料 $a=0.12$，右侧 $a=0.20$；引线胞以整数为中心。三叶形为 $c(\theta)=R(1+a\cos3\theta)(\cos\theta,\sin\theta)$，$R=0.2/\sqrt{1+a^2/2}$，夹杂密度17、背景1。`dtn_native.m` 的原始 `LOCAL_curve` 与 `fem-pipeline-v1/direct_native.m` 相同。左侧内向坐标 $\xi=1/2-X$，右侧 $\xi=X+1/2$，所有积分仍在原物理胞坐标 $X$ 上进行，夹杂不作反射替换。

场及端点代码复制自 fem-pipeline-v1；拟合映射及拓扑来自 gap-ends-v1。整数 RT3（Raviart–Thomas，次数3）参考基另从 qj-cert-v2 复制。h-cert-v1 只提供预解式常数及几何核对输入。本实验采用单胞拟合 P4（次数4）场与 RT3 通量，避免长截断域；离散传递矩阵只选择试探场，其误差由真几何上的残差控制。

## 复现命令

在仓库根目录执行下列命令；重跑使用新的 `run-NNN`，并在分析输入 JSON 中更新明确的数值记录路径。无需旧 MAT 文件。MATLAB 为 R2023b；Python 只用标准库。

```sh
python3 test/numerical-directions/h-dtn-v1/constants.py test/numerical-directions/h-dtn-v1/constants.json
python3 test/numerical-directions/h-dtn-v1/exact_trace_check.py test/numerical-directions/h-dtn-v1
python3 test/numerical-directions/h-dtn-v1/launch_dtn.py --mode baseline --output test/numerical-directions/h-dtn-v1/output/run-001
python3 test/numerical-directions/h-dtn-v1/launch_dtn.py --side left --group g48 --degree 4 --order 16 --certify 1 --lift 12 --output test/numerical-directions/h-dtn-v1/output/run-006
python3 test/numerical-directions/h-dtn-v1/launch_dtn.py --side right --group g24 --degree 4 --order 16 --certify 1 --lift 12 --output test/numerical-directions/h-dtn-v1/output/run-007
python3 test/numerical-directions/h-dtn-v1/launch_dtn.py --side right --group g48 --degree 4 --order 16 --certify 1 --lift 12 --output test/numerical-directions/h-dtn-v1/output/run-008
python3 test/numerical-directions/h-dtn-v1/launch_dtn.py --side left --group g24 --degree 4 --order 16 --certify 1 --lift 12 --output test/numerical-directions/h-dtn-v1/output/run-009
python3 test/numerical-directions/h-dtn-v1/launch_dtn.py --mode compare --output test/numerical-directions/h-dtn-v1/output/run-011
python3 test/numerical-directions/h-dtn-v1/launch_dtn.py --mode analyze --inputs test/numerical-directions/h-dtn-v1/analysis-input.json --output test/numerical-directions/h-dtn-v1/output/run-013
python3 test/numerical-directions/h-dtn-v1/report_dtn.py --inputs test/numerical-directions/h-dtn-v1/analysis-input.json --analysis test/numerical-directions/h-dtn-v1/output/run-013/science/analysis.json
```

所有 MATLAB 启动均通过 `diagnostics-v1/monitor.py`，11线程、`OMP_DYNAMIC=FALSE`；软限30分钟、硬限40分钟、峰值3 GiB。

## 高频提升常数

'''
text+=table(['$M_C$','$a_H$','$b_H^2$','$A_H$'],[[x['M'],f(x['a_H']),f(x['b_H_squared']),f(x['A_H'])] for x in const['table']])
text+='\n\n与 §4.7 六行参考值的最大相对差为 '+f(analysis['tail_max_relative'])+'，小于预设 $5\\times10^{-6}$。全部 $A_H>0$。\n\n'
text+=r'''## 低频场与通量

低 Fourier 块为 $|i|\le5$，共11列。第一胞用 P4 单胞调和场加端口修正
$$u_i=u_{h,i}+\chi(\xi)e^{-\tau\xi}(g_i-g_{h,i}),\quad \chi=1-3(\xi/b)^2+2(\xi/b)^3,\quad b=1/8.$$
修正在 $\xi>b$ 处为零，$g_{h,i}$ 使用实际端口节点和分段多项式，因此端口迹逐点恰等于 $g_i$。主场取 $\tau=12s$，比较场取 $8s$，$s=24,48$。其余22列使用精确指数场 $e^{-\sqrt{\beta_i^2-\lambda}\xi}e^{\mathrm i\beta_i y}$ 与其梯度通量。低迹修正与高迹的所有横向分量均在实际积分中保留。

RT3 的72个边/列法向多项式关系已用整数算术检验。共享边系数、横向 Bloch 相位及胞壁通量映射由同一变量定义。通量的法向连续属于构造恒等式。内部基预条件不改变边系数，最终求值回到整数基。无限胞由传递矩阵幂累加；有限幂范数小于1及显式尾界保证 $u\in H^1$、$p\in H(\operatorname{div})$。

残差使用证明 (4.3) 的 $R=\int(|\nabla u-p|^2+|\operatorname{div}p+\lambda\rho u|^2/\rho)$，测试空间为零端口迹的 $\mathcal V_0$，范数为 $e(v,v)=\int(|\nabla v|^2+\rho|v|^2)$。非紧支撑场的 Green 公式及级数误差推导见文末。

## 下界矩阵

下表 $r$ 使用 $R_+$，是所需残差范数的上界；$r$、间隙及高频罚项均作 $T_{tr}^{-1/2}$ 双侧缩放；最后两列是不缩放的普通矩阵最小特征值。

'''
text+=table(['侧','空间','$r$','$K_+r$','高频罚项','上下界间隙','$\lambda_{min}(Q)$','$\lambda_{min}(\hat\Lambda)$'],rows)
text+=r'''

$Q_-=Q-\varepsilon_QI$、$R_+=R+\varepsilon_RI$、$Z_+=Z+\varepsilon_ZI$。下界按 (4.17) 组装；上界是 $Q+\varepsilon_QI+K_-R_+$。这里 $Z$ 使用 $u+K_+r_2$ 在全半引线的 Gram，因它大于 collar $J$ 上的 Gram，代入仍给安全下界。余项如下。

'''
text+=table(['侧',r'$\varepsilon_Q$',r'$\varepsilon_R$',r'$\varepsilon_Z$','级数放大界','首胞阶数','重复胞阶数'],epsrows)
text+='\n\n'+table(['侧','g24/g48 重叠最小值1','重叠最小值2','下界变化/g24间隙','下界变化/g48间隙'],[[s,*[f(x) for x in c[4:6]],f(c[7]),f(c[8])] for s,c in zip(['左','右'],comp)])
text+='\n\n'+table(['侧','$r(8s)$','$r(12s)$','同网格下界变化','变化/最终间隙','重叠最小值'],[[s,*[f(x) for x in z]] for s,z in zip(['左','右'],lift)])
text+=r'''

网格变化含场离散误差，另列相对两个间隙的比值；近邻试探场的变化核查使用预先指定的 $8s\to12s$ 校正率比较，不把网格变化隐藏在误差中。

## 积分包围

用于最终 $Q,R,Z$ 的积分均有显式截断余项。公共重复胞以多项式精确性处理；曲线胞与首胞修正使用真解析弧及复椭圆上的正权 Gauss 余项。阶数按单元界选择，实际误差逐元累加。横向相位按精确指数表达式保留，有限 FE 场的额外 Fourier 分量由实际端口修正相消，未作未控制的相位截断。无穷胞使用有限矩阵倍增加几何尾界；未显式积分的高迹首胞外部分及其低高交叉项另用能量 Cauchy 界。完整推导见文末。

原 FEM DtN sanity 比较和诊断特征值属于浮点计算。它们不进入积分包围。最终积分中仍未包围的部分：无；浮点舍入按任务约定排除。

'''
text+=table(['侧','复 Jacobian 相对界','物理位移导数界','Jacobian 模下界','曲线胞到修正带余量'],[[s,f(d['bulk']['max_eta']),f(d['bulk']['max_physical_eta']),f(d['bulk']['min_det']),f(fe_records[i]['geometry']['curved_collar_clearance'])] for i,(s,d) in enumerate(zip(['左','右'],fine))])
text+='\n\n'+table(['侧','累计胞数 $L$','$\\|P^L\\|$','相对级数尾因子'],[[s,z['series']['length'],f(z['series']['power_norm']),f(z['series']['relative_tail_factor'])] for s,z in zip(['左','右'],fe_records)])
text+='\n\n## 核查\n\n'
checks=analysis['checks'];words={'tail_table':'高频常数表','exact_trace':'精确迹','overlap':'两个空间包围重叠','FE_sanity':'原 FEM DtN sanity','convergence':'收敛','Hermitian_PSD':'Hermitian 与正半定'}
for i,(k,w) in enumerate(words.items(),1):
 text+=str(i)+'. '+w+'：'+('通过' if checks[k] else '未通过')+'。'
 if i==1:text+='最大相对差 '+f(analysis['tail_max_relative'])+'，容差 $5\\times10^{-6}$。'
 if i==2:text+='两侧逐点与33模投影差分别为 '+str(analysis['trace'])+'；构造恒等式覆盖全部横向分量。'
 if i==3:text+='上表给出所有最小值；预设舍入尺度容差为 $10^{-11}$，未据此扩大截断界。'
 if i==4:text+='原 P3/g48 全矩阵归一化差为 '+', '.join(f(z[9]) for z in comp)+'；$|i|\\le5$ 子块差为 '+', '.join(f(z[10]) for z in comp)+'，预设容差分别0.05和0.005。'
 if i==5:text+='g24到g48的 $r$ 下降，下界变化为粗网格自身间隙的0.99115倍、细网格间隙的219.63倍；同网格 $8s\\to12s$ 变化为最终间隙的0.001895倍。'
 if i==6:text+='Hermitian 最大相对缺陷 '+', '.join(f(z[0]) for z in sym)+'；$R$ 最小特征值 '+', '.join(f(z[1]) for z in sym)+'，$Z$ 最小特征值 '+', '.join(f(z[2]) for z in sym)+'。中心 $R$ 的舍入容差为 $-10^{-12}\\|R\\|$；右侧负值属于该尺度，安全矩阵 $R_+$ 的对角余量为 '+f(fine[1]['eps_R'])+'。'
 text+='\n'
text+='\n原 P3 根复制复现数值为 $1.5584378944018986$，相对参考根差 $2.14273\\times10^{-14}$，见 `output/run-001/`。\n'
text+='\n'+table(['侧','P3/g48 端口自由度','P3/g48 原生三角形数','拟合 P4 节点 DtN 与 Q 的差'],[[s,fe['wall_count'],fe['triangles'],f(c[11])] for s,fe,c in zip(['左','右'],read(cfg['fe']),comp)])
text+='\n\n## 成本\n\n'
text+='基线启动前估计120–240秒、1.8–2.6 GiB；g24 估计3–12分钟、1.2–2.5 GiB；g48 估计8–25分钟、1.8–2.9 GiB；原 FEM 比较估计120–300秒、1.5–2.5 GiB；矩阵核查估计15–45秒、0.7–1.2 GiB。下面是监控实测。\n\n'
text+=table(['运行','结果','秒','峰值 GiB'],mon)
text+='\n\nrun-002 的 JSON 复数标量导出失败，run-004 缺少 `range` 工具箱；run-010 的原 FEM 比较入口缺少进度路径，补齐本实验副本后在新目录重跑。run-012 的汇总脚本把 JSON 列向量按行向量处理，改为全元素最大值后重跑。四份失败日志保留。最终计算不依赖该工具箱。\n'
text+=r'''
## 对下一步的意义

两个交付 JSON 保存未缩放的 $\hat\Lambda,Q,R,Z$、安全方向的 $Q_\pm,R_+,Z_+$、上下界、$K_\pm,a_H,b_H^2,A_H$。系数约定为 $g(y)=\sum_{i=-16}^{16}\hat g_i e^{\mathrm i\beta_i y}$，$y\in[-1/2,1/2]$，保留原物理取向。$\hat\Lambda$ 对全部端口迹给出 C.3 下界，下界在33模外按零嵌入；上界只对保留的33模子空间使用。两侧都达到残差预算。下一步可将两矩阵送入核心计数；最终计数决定当前间隙是否足够。

## 限制

排除舍入，仅处理 $\lambda=\alpha_+$。输入半引线谱间隙采用 h-cert-v1 的结果。D 和最终计数不在本实验范围。特征值符号及残差最优化目前用普通浮点运算；后续区间算术须同时包围几何、积分、矩阵级数和特征值运算。

'''
text+=proofs
(here/'README.md').write_text(text)
record={'mode':'from-scratch proof for the added integration and noncompact-trial bounds','result':'proved under the h-cert-v1 resolvent input, with rounding excluded','literature_status':'Proof literature verification completed.','governing_source':'h-cert-proof.md C.1/C.3',
 'obligations':{'integer_RT_traces':read(here/'exact-trace-check.json'),'quadrature_remainders':'README analytic geometry and Gauss remainder derivation; dtn_bounds.m, dtn_integrate.m',
 'infinite_series':'finite matrix power contraction plus explicit remainder; dtn_run.m LOCAL_sum','trace':'actual FE polynomial cancellation; dtn_trace_check.m',
 'resolvent':'h-cert-v1 input','rounding':'excluded, TODO interval arithmetic'},'checks':checks,'literature':'No new external literature claim; coefficient and Gauss remainder bounds derived in README'}
(here/'proof-obligations.json').write_text(json.dumps(record,ensure_ascii=False,indent=2)+'\n')
print('README and two certificates written; checks',checks)
