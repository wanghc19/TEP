# I2.2 实轴结构资格与端点实验独立审查

> **当前补充结论（2026-08-13）：**本页原有 `STOPPED AT THEORY GATE` 仍是 raw $H$ strict
> inertia 路线的历史 verdict，不作追溯改写。按后续总路线和
> [[research/projects/eig-apost/implementation/i2/design-2-2#19 当前路线修订：Hermitian-part endpoint sign-count|design §19]]，
> 当前 `inertia-a1` 只计算 $H_{\mathrm{sym}}=(H+H^*)/2$ 的 endpoint sign count，作为
> numerical corroboration；其独立跑后审查见本页末尾“当前 Hermitian-part attempt”。

## 审查结论

阶段 verdict 为

`PASS WITH CONDITIONS / STOPPED AT THEORY GATE / I2_2_STOP_THEORY_GATE`。

这里的 `PASS WITH CONDITIONS` 只表示：冻结的最低成本双端点 structure diagnostic 已完整、
可复现、忠实地运行到预注册的理论门。它不是 inertia、实轴 root、continuous physical
eigenvalue 或 posterior estimator 的 PASS。两端 inertia 的唯一合规结果是
`NaN/UNAVAILABLE`，首个科学停止为 `EXACT_HERMITIAN_NOT_ESTABLISHED`。

权威理论和实验合同见
[[research/projects/eig-apost/implementation/i2/design-2-2|I2.2 frozen design]]。实验设计、
Revision A、命令、append-only 历史和全部证据统一从
[[test/i2/h-inertia/README|I2.2 endpoint-structure experiment index]] 进入；本页不直链
零散源码、CSV、MAT 或日志。

## 审查范围与成功标准

本轮只审查以下问题：

1. 在 $T(k)$ 可逆的预注册实轴肩点上，候选
   $H(k)=A(k)T(k)^{-1}$ 是否忠实实现原 $A(k)$ 的可逆右坐标变换；
2. $T$、center block、half-guide graph、DtN 和 raw $H$ 的结构诊断是否来自同一冻结
   fine、$M=48$ evaluator；
3. 是否已经具备定义 endpoint inertia 所需的 exact finite Hermitian identity 与整个闭肩区间
   same-family continuity；
4. 若理论门未闭合，runner 是否在任何 `eig/ldl/inertia`、locator 或 root solve 前停止，并把
   positive/negative/zero counts 写成 unavailable，而不是手工对称化后强行计数。

成功不要求本轮定位 root。成功要求的是：要么理论与数值资格完整、可解释 inertia；要么在
第一个未闭合门准确停止，并把两端原始诊断和失败边界完整保存。

## 理论核验

### 已证明的有限维命题

实际 block formula 为

$$
A=N_0-LT,
\qquad
H=A/T,
$$

其中 $T$ 把中心 incoming-amplitude 坐标换成两墙 Dirichlet trace。只要 $T$ 可逆，便有

$$
A=HT,
\qquad
\ker H=T\ker A.
$$

因此 $H$ 与 $A$ 在该点具有相同 rank、nullity 和 singularity，但不具有字面相同的右核。
本轮还由逐 channel 公式证明：$T$ 在整个冻结 shoulder interval 上远离 Wood/empty-slab
Dirichlet singularity，且 center block $C_0=N_0T^{-1}$ 在实参数上 exact Hermitian。

### 未闭合的证明义务

对 actual MFS/collocation/BIE/QZ half-guide graph，尚无 exact-arithmetic 证明

$$
D_s^*N_s=N_s^*D_s,
$$

所以不能推出实际 $\Lambda_s=N_sD_s^{-1}$ 或 raw $H$ 在有限维上严格 Hermitian。另一个独立
blocker 是：两个端点不能证明整个闭肩区间内同一 analytic/QZ subspace、chart 和 inverse
factors 连续且无 pole。故
`exact_finite_hermitian_proof=false` 与
`continuous_same_family_interval_proof=false` 均正确保持。

标量反例 $h(k)=k-a+\mathrm{i}\varepsilon$ 表明：Hermitian defect 即使任意小，实轴上也可
没有 zero；对 $(H+H^*)/2$ 的 inertia jump 不能替代原 $H$ 的实根。因此数值 defect 只能是
implementation oracle，不能反向证明 exact Hermitian。

### 文献条件

本轮逐页核验了本地 Fliss (2013) 原文的 Proposition 3.1、3.3、4.3、4.8、4.10 以及
Theorem 4.1、4.5、4.9。它们支持 fixed real quasi-periodicity 下 continuous physical operator
的自伴谱结构、exact DtN reduction 与实参数 characterisation；其假设没有自动传递到当前
sharp-disk、finite MFS/BIE/QZ arrays。没有把 continuous theorem、smooth-profile Track A gap
或 unit-circle QZ split 写成当前 finite Hermitian 证明，也没有下载新文献。

## 三方职责与冻结过程

- **Researcher：**给出 $A$--$H$ 奇异等价、$T$ 区间可逆、center block Hermitian、
  half-guide Lagrangian 等价条件和 conditional inertia 命题；明确两个 proof blockers。
- **Engineer：**复用只读 I2.1 evaluator，冻结 L14 nodes 3/5、evidence schema、资源、失败顺序
  和零调用计数；实现 $A,T,N_0,L,H$ 的同对象 adapter 和 fail-close runner。
- **Skeptic：**独立审查理论、设计--实现映射、freeze、两次 attempt 和跑后 evidence；既不把
  near-Hermitian 数值辩护为证明，也不因预期 STOP 放宽 gate。

Skeptic 对 Revision A freeze aggregate
`7bc0d18cb7356c9569ac43bd03c3f1a98cc038df7d5bb17d08a049dd08ae16ed`
给出 `PASS WITH CONDITIONS`，只授权一次 diagnostic command。运行前 manifest 全部匹配，
新 output tag 不存在。

## 运行历史

### 非实验 MATLAB startup 失败

Engineer 在 freeze 前误发起一次只读 MAT schema command；MATLAB 约 `2.3 s` 后在
startup/crash-report 权限层 fatal exit，未进入 `load`、未调用 evaluator、未产生 output。
该事件单独计入 campaign 时间，不提供数值证据。

### `diag-a1`：不可变 schema 失败

首次正式 attempt 在 `16.368607833333332 s` 后因
`MATLAB:catenate:dimensionMismatch` 停止。seed 与左端点已经运行，但 $1\times8$ seed-object
struct 与 $1\times13$ endpoint-object struct 的纵拼失败，右端点和 raw matrix ledger 未形成。
它是 evidence-schema implementation failure，不是理论或端点数值 verdict。该目录、旧 freeze
和 result hash 保持 append-only，不得覆盖或补造。

Researcher--Engineer 随后只允许 Revision A：核对相同字段 schema 后用列向 `(:)` 追加，新增
`EVIDENCE_SCHEMA_FAILURE`，锁定 `diag-a1` 为 immutable parent，并使用新 tag/freeze。端点、
evaluator、formula、threshold、proof flags 和解释均未改变。Skeptic 重新跑前审查后才授权
第二次 attempt。

### `diag-a2`：完整 structure diagnostic

从仓库根目录实际运行：

```sh
/Applications/MATLAB_R2023b.app/bin/matlab -batch "addpath(fullfile(pwd,'test','i2','h-inertia')); run_i22('diagnostic');"
```

command body 与登记命令相同，runtime 为 MATLAB R2023b/public `lsqminnorm`。结果为

`I2_2_STOP_THEORY_GATE / EXACT_HERMITIAN_NOT_ESTABLISHED`。

本次 elapsed 为 `21.19280975 s`，runner active-object snapshot peak 为
`54.3655872345 MiB`（不是 OS RSS），共 3 个 checkpoints。连同 startup 与 `diag-a1`，campaign
累计 `39.8614175833 s`，远低于预算。没有自动 retry。

## 数值审查结果

### 对象、端点与 provenance

- 左右端点恰为 I1.3 L14 nodes 3/5：
  $k_L=1.8327701568603514$、$k_R=1.8327705383300779$，均严格位于 I2.1 disk 实直径内；
- 两端使用同一 evaluator、branch、QZ clusters、fixed rows、charts、ordering 和 solver；
- 2 endpoint、20 factor、4 QZ、2 structure rows 完整；34 object rows 对应 seed 与两端 actual
  sizes；8 项 lineage 和全部 source hashes 匹配；
- 两端 QZ 均为 97 stable / 97 unstable / 0 neutral；inherited factors 全部通过。

### $T$ 与点态等价

两端均有 `rcond(T)=0.5`，$\sigma_{\min}(T)$ 约为 $0.9958518$，且
$\min_m|1-E_m^2|$ 约为 $0.9999828$。$A=N_0-LT$、$H=A/T$ 与 $A=HT$ 的 normalized
residual/defect 约为 $10^{-21}$--$10^{-19}$，远低于冻结阈值。该结果支持两端实现确实是
同一 finite singularity problem 的可逆坐标表示。

### 结构 defect 与 inertia

center block $C_0$ 的 Hermitian defect 为约 $10^{-23}$--$10^{-19}$；$\Lambda_\pm$、graph
Lagrangian 与 raw $H$ defects 为约 $0.7\times10^{-16}$--$1.7\times10^{-16}$。它们是很强的
点态实现诊断，但始终标记为 `DIAGNOSTIC_ONLY`，没有改变 proof flags。

两端 `n_pos`、`n_neg`、`n_zero` 和 `min_abs_eig` 全部为 `NaN`；algorithm 为
`NOT_RUN_EXACT_HERMITIAN_GATE`，jump 为 `UNAVAILABLE`。gates 10--11 为理论 FAIL，endpoint
separation 与 inertia jump 为 `NOT_REACHED`。inertia、locator、scan、root refinement、
symmetrization、derivative 和 estimator 调用均为 0。

Engineer 还从保存的 compact MAT objects 做了不调用 MATLAB 的独立复算，确认矩阵定义和
点态 residual 与 CSV 在浮点累加差异内一致。Skeptic 因其只读/不运行约束未独立解析 MAT
arrays，但复核了 producer/source hashes、尺寸、CSV/result/report/log 和 append-only 历史；
该审计差异不改变 verdict。

## Skeptic verdict 与 claim boundary

Skeptic 跑后 verdict 为 `PASS WITH CONDITIONS`，blocker 数为 2：

1. actual finite graph/DtN 的 exact Lagrangian/Hermitian identity 未证明；
2. whole shoulder interval 的 same-family continuity/no-pole qualification 未证明。

本轮可保留：两端同一冻结 finite evaluator 可复现；branch/QZ/chart/factors 健康；$T$ 在两端
明显可逆；$A$--$H$ 点态关系以浮点精度闭合；raw arrays 呈机器精度量级 near-Hermitian。

本轮不能保留：inertia jump、finite real-root existence、root coordinate、simple/geometric
root、continuous physical eigenvalue 或 posterior estimator。I2.1 的 conditional count-one
结论不受影响，但不能与本轮 `UNAVAILABLE` inertia 合并成实轴 root。

## 剩余 blocker 与下一门

若坚持 inertia 路线，必须另行闭合 exact finite Lagrangian/Hermitian identity 和 entire closed
shoulder interval 的 same-family continuity；需要新的设计、freeze 和 Skeptic 审查，不能只因
当前 defect 小而翻转 flag。

鉴于 I2 的核心目标是尽快得到 estimator 可消费的高可信离散 root，不建议只为定理完备性
无限扩张该支线。若项目选择切换方法，最低成本候选是只在 I2.1 已隔离小圆盘内做 local
complex root refinement，直接报告 imaginary part、原 $A$ residual、factor health 和
uncertainty；不得做大范围复扫描，也不得强行把 imaginary part 置零。该选择仍是全新的方法
切换，本轮没有授权其设计、实现或运行。

## 2026-08-13 总路线复审后的适用范围

以上 verdict 仍是 I2.2 endpoint-inertia 支线的忠实历史审查，不作追溯改写：在没有 exact
finite Hermitian identity 与整段同族连续性时，不能计算或解释 endpoint inertia，也不能用
手工对称化矩阵制造 jump。总路线复审只修正了该结论曾被扩大使用的范围。

底层 global physical operator 的自伴实谱，以及适定假设下 exact-DtN pencil 对该谱的表征，
而不是某一版离散矩阵的 exact Hermitian 性，决定正频率搜索优先沿实轴进行。因此，本页的
两个 proof blockers 现只阻止 inertia、signed-eigenvalue
crossing 和“finite determinant zero 精确在实轴”的主张；它们不再阻止在 I1.3/I2.1 已冻结
窄区间上，对未经手工对称化的原始 $A_{\mathrm{def}}^D$ 做 derivative-free bounded real-axis
refinement。

现行默认顺序改为：先取得 real-axis constrained discrete candidate，再在原始矩阵上检查左右
residual、backward error、$\sigma_1/\sigma_2$、factor health、full-graph/Schur parity、非零
center/port participation、boundary matching 与独立复现。near-Hermitian、reciprocity 和
Lagrangian defects 只作为未校准结构 diagnostics/uncertainty components 记录，不单独定义
成功，也不能直接换算为 root error。local complex refinement 也不再是 proof failure 后的
默认路线；只有持续实轴 residual floor、candidate shift 与 uncertainty ledger 不相容或
左右近核/phase 异常时，才可另行设计并审查。off-axis displacement 只有此后才能测量。
最新行动边界见
[[research/projects/eig-apost/implementation/i2/README|I2 guide]] 与
[[research/projects/eig-apost/DECISIONS|decision ledger]]。

## 2026-08-13 candidate--error 路线再次复审后的适用范围

本页此前关于 raw finite $H$ 的结论继续保持：没有 exact finite Hermitian identity 时，历史
实验不得把 NaN 改成 mathematical inertia，也不得从 near-Hermitian defect 推出严格实根。
这仍是不可追溯改写的数值证据边界。

当前项目不再把“证明 candidate 等于 nearby exact finite zero”或“完成 bounded root locator”
作为 I2 的终点。I2.2 只复用 I1.3 已确定的左右端点，检查一个清楚标注对象、数值容差和
unresolved band 的 endpoint sign-count/inertia-like quantity 是否出现 jump。即使观察到稳定
jump，它也只提高 continuous physical eigenvalue candidate 的可信度；没有 jump、unresolved
或不稳定同样是有效结果，不能通过移动端点或手工对称化解释来迎合预期。

后续 I2.3 已压缩为一个明确的跨离散阶数 candidate 漂移实验：冻结不同离散阶数和统一定位
规则，比较同一 physical mode，并报告漂移、定位 uncertainty 与最低原 evaluator、factor、
field、boundary、mode-identity 和复现诊断。其输出直接进入 I3，不再另设 I2.4；误差来源的
识别和分解属于 I3。exact finite structure、额外 contour、复数 refinement、derivative、
adjoint、transport 和 denominator 只有在当前 estimator 或上界路线实际需要时才升级；它们
不再由本历史 review 自动生成 blocker。

## 当前 Hermitian-part attempt：`inertia-a1`

### 对象、判据与运行

当前入口保持 raw $H=A_{\mathrm{def}}^D/T$，只对
$H_{\mathrm{sym}}=(H+H^*)/2$ 做 endpoint sign count。绝对 resolution band 为

$$
\eta=\lVert H-H_{\mathrm{sym}}\rVert_2
  +100n\epsilon_{\mathrm{mach}}\max(1,\lVert H_{\mathrm{sym}}\rVert_2),
$$

并以系数 $50/100/200$ 的三组完整 counts 做预注册 sensitivity check；任何变化都应降为
`UNRESOLVED`。Skeptic 在静态 freeze 全部匹配后只授权一次 `inertia-a1`。实际 MATLAB 命令
从 repository root 运行，用时 $20.0001$ s，active-object snapshot peak 为 $63.4584$ MiB；
没有失败或 retry。output 只含 `result.mat` 与 `report.md`。

### 结果

两端分别为 $k_L=1.8327701568603514$ 与 $k_R=1.8327705383300779$。主带得到

| endpoint | $n_+$ | $n_-$ | $n_{\mathrm{unresolved}}$ | $d_H$ | $\eta$ | $\min|\lambda(H_{\mathrm{sym}})|$ |
|---|---:|---:|---:|---:|---:|---:|
| $L$ | 194 | 0 | 0 | $8.3697\times10^{-14}$ | $2.6027\times10^{-9}$ | $8.2246\times10^{-7}$ |
| $R$ | 193 | 1 | 0 | $9.6905\times10^{-14}$ | $2.6027\times10^{-9}$ | $1.5492\times10^{-6}$ |

因此 $\Delta_-=+1$、$\Delta_+=-1$，分类为 `JUMP / SINGLE_JUMP`；$50/100/200$ 三组
counts 完全一致，`band_sensitivity=STABLE`。端点最小绝对 eigenvalue 分别约为主带的
$316$ 与 $595$ 倍，端点分类有清楚余量。$d_H/\lVert H_{\mathrm{sym}}\rVert_2$ 约为
$1.39\times10^{-16}$ 与 $1.60\times10^{-16}$，只说明同一实现呈机器精度量级 near-Hermitian，
不构成 exact structure proof。

### 独立审查结论与边界

Researcher 判定该结果完成 I2.2 的 numerical corroboration 交付，并允许进入另行设计的 I2.3；
进入 I2.3 不以必须观察到 jump 为条件。Engineer 从保存的 eigenvalues、raw $H$ 与
$H_{\mathrm{sym}}$ 独立复算主带和 sensitivity counts，确认
$H_{\mathrm{sym}}=(H+H^*)/2$、report/result 一致、对象等价 gates 通过、资源合规。

Skeptic 的独立 post-run verdict 为 `PASS WITH CONDITIONS`（高置信、零 blocker）。其只读
复核重新解析保存的 MAT 数据、逐项重算 $50/100/200$ bands 与 counts，并以独立 LAPACK
eigensolve 核对左端谱；全部保留 `SINGLE_JUMP` 分类。Skeptic 同时强调：历史 output 的文件数、
修改时间与已登记的 `diag-a1` result identity 均无覆盖迹象，但 pre-run freeze 未登记每个历史
output 文件的完整 digest，因而不得声称已经密码学证明所有历史字节均未变化。

本结果只能称：冻结 fine-$M=48$ evaluator 的 Hermitian-part endpoint sign count 出现稳定
单步差，为已有 candidate 提供 numerical corroboration。`SINGLE_JUMP` 只描述两个端点的
count difference，不证明区间内恰有一个 crossing。它不提供 raw-$H$ mathematical inertia、
raw finite real zero、root coordinate、continuous physical eigenvalue 或 posterior error estimate；
也未闭合整个区间的 same-family continuity/no-pole 条件。I2.1 仍是 sampled conditional count one，
不得与本结果拼接成实根定理。
