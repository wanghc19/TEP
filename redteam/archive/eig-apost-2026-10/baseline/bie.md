# BIE + DtN baseline

本记录在 `codex/epost`、提交 `e1866b7130c81ecedf756106ca2c04a5801ec3b0` 的工作区只读核对。它锁定用户所述与 FEM 相差约 $10^{-12}$ 的实际 BIE 算例；不是 I7/I8 的 $k\simeq1.756$ 算例。**CONFIRMED / ESTABLISHED（来源身份）**。

## 原始来源和版本

| 对象 | 源码或原始数据 |
|---|---|
| 搜索入口及配置 | `test/i9/search-v1/search_i9_run.m`、`search_i9_config.m`、`search_i9_physics.m` |
| 搜索正式运行 | `test/i9/search-v1/output/attempt-3/run-02/`；原始 `candidate-evidence-0201.mat`、`candidate-evidence-0213.mat` 在场；本子审计未载入 MAT |
| 固定候选新构场与估计 | `test/i9/estimate-v1/estimate_i9_run.m`、`estimate_i9_numeric.m`、`estimate_i9_config.m` |
| 估计正式运行 | `test/i9/estimate-v1/output/attempt-1/run-01/result.json`、`evidence.mat`、`status.json` |
| 连续残差定理 | `research/projects/eig-apost/phase3-analysis/resolvent-bound/s-framework.md` 的 F1–F2；`s-trace.md` 的 T1–T5 |

本次检查直接读了源码、上述 JSON 的标量及结构化配置；没有仅从 README 抄录。另尝试用项目 Conda 环境读取搜索 MAT，因该环境没有 SciPy 而未执行；这是依赖缺失，不是反例。完整 MAT 原件留在原目录，后续可由根代理以 MATLAB 读取。

## 同一物理问题

无限条带 $B=\mathbb R\times(-1/2,1/2)$，$u(x,y+1)=e^{\mathrm i\beta}u(x,y)$，$\beta=0.5$。作用为 $A(\beta)u=-\rho^{-1}\Delta u$，谱参数 $\mu=k^2$。材料普通法向导数连续，质量空间为 $L^2(B,\rho\,\mathrm dx\,\mathrm dy)$；这是所选标量 TM 约定，不能换成 $\rho^{-1}\partial_\nu u$ 连续的另一偏振。

中心胞元 $(-1/2,1/2)\times(-1/2,1/2)$ 的材料为4，背景1。中心曲线是

$$
x(t)=0.2(1.5+0.3\cos5t)\cos t,\qquad
y(t)=0.2(1+0.3\cos5t)\sin t.
$$

左右 lead inclusion 的材料均为17；在各胞元自身坐标中

$$
r_\pm(t)=\frac{0.2(1+a_\pm\cos3t)}{\sqrt{1+a_\pm^2/2}},
\quad a_-=0.12,\quad a_+=0.20.
$$

lead 周期为1，中心分别平移至整数 $x=\pm1,\pm2,\ldots$，两侧保持各自全局朝向，没有把负侧镜像为正侧。材料内部波数用 $\sqrt\rho k$。

源码核对：`+geom/construct_cont.m:33–45`、`estimate_i9_geometry.m:6–21`、`estimate_i9_numeric.m:111–130`；与 FEM `refine_i102.m:676–703` 的解析形状一致。参数/几何身份已经核对，不意味着 FEM 积分或几何近似误差已认证。

## 搜索和估计是两个不同计算

搜索粗层中心/左/右 Nyström 点数为256/128/128；fine为512/256/256。Rayleigh $m=-48,\ldots,48$，$K=97$；proxy tuple为 `(N_side,N_top,N_proxy_edge,M_pw)=(160,160,80,32)`，$H=1.1$，proxy距0.2。FMM请求精度 $10^{-12}$，11线程。搜索使用最小奇异值比值的局部网格加密，不是已认证的连续非线性特征根定位。

固定估计在相同 $k$ 从零重新解中心和两侧密度，再冻结；非原搜索向量的直接复用。它使用512/256/256构场、768节点材料/墙评价、左右各40胞元，加各自观测比率外推；局部质量用中心背景中的安全圆盘 $(0,3/8)$、半径 $1/16$、32×64点。

| 原始量 | 数值 | 资格 |
|---|---:|---|
| $k_{\rm BIE}$ | 1.5584378941820909 | 数值候选 |
| $\mu_{\rm num}=k^2$ | 2.4287286700227098 | 普通浮点乘积 |
| 最后搜索窗口全宽 | $1.6209256159527285\times10^{-14}$ | 离散搜索分辨率，不是谱半径 |
| `aphys_sigma` | $1.0508097636631883\times10^{-13}$ | 加权有限矩阵残差诊断 |
| `aphys_ratio` | $2.9344919212372774\times10^{-14}$ | 无量纲有限矩阵比值 |
| $C_{\rm num}$ | 9.578112278425445 | 采样几何导出的普通常数 |
| $\varepsilon_{\rm num}$ | $2.0547899536692847\times10^{-12}$ | 连续跳跃公式的数值评价 |
| $U_{\rm num}$ | 0.12342045035909599 | 同场局部圆盘范数求积值 |
| $R_{\rm num}$ | $7.745852555568109\times10^{-10}$ | **$\mu$尺度；`UNCERTIFIED_RNUM`** |
| 对应普通 $k$ 最大半径 | $2.4851335382379565\times10^{-10}$ | 对上行的尺度换算，仍未认证 |

其中转换为

$$
R_k=\frac{R_\mu}{\sqrt{\mu}+\sqrt{\mu-R_\mu}},\qquad 0<R_\mu<\mu.
$$

结果出处：`result.json:85–102`；搜索出处：`search-v1/output/attempt-3/run-02/comparison.json` 的 `candidates[experiment=current,interval_id=1]`。后者同时保留 `BOUNDARY_UNRESOLVED` 右端趋势，不能据唯一已观察dip称全窗口只有一个本征值。

原始两侧有限QZ分别均有97稳定/97不稳定对，离单位圆的 homogeneous distance 最小值为0.5828304842、0.5751318206，QZ残差约 $4.37\times10^{-15}$、$5.35\times10^{-15}$。这些支持当前有限矩阵远离带边，但没有认证连续 lead gap 或图投影可逆性。

## 实现依赖与成本

实际依赖链：新 I9 实验入口 → `bloch.construct_S` → `op.construct_A_QP`、`bloch.incident_rhs`、`bloch.farfield_extractors` → `kernel.precomp_proxy`、`kernel.qpgreen_mfs_pairmat`、Kress核及 `utils.triginterp`；smooth proxy项经 `hfmm2d`，中心自由空间核及regular diagonal仍有直接Hankel评价。

当前 FEM I10.2 不调用这些BIE包或其DtN矩阵；它有本地FE装配、Schur补和另一个QZ线性化。二者共享物理公式、QZ思想及 MATLAB 线性代数库，不是完全无共同假设。

历史监控值只反映各自声明的计算：搜索 `status.json` 642.986955秒/1,422,639,104 B；固定估计96.0841365秒/1,389,166,592 B。搜索和估计的冷成本可相加为739.0710915秒，但这不是同一可信精度下的公平对照，也未包含所有审查/绘图/首次工具准备成本。该历史配置资源许可曾为3GB；本redteam的新实验必须遵守2 GiB，不能照抄旧许可。

关联：[[redteam/archive/eig-apost-2026-10/theory/bie-audit]]、[[redteam/archive/eig-apost-2026-10/reports/error_certification]]、[[redteam/archive/eig-apost-2026-10/reports/shared_dtn_risks]]。
