# I4.1 候选方法比较

状态：`CANDIDATE COMPARISON COMPLETE / SELECTED ROUTE PASSED WITH CONDITIONS`
证据：[[research/projects/eig-apost/implementation/i4/sources|sources]]
选择稿：[[research/projects/eig-apost/implementation/i4/method-4-1|method-4-1]]

## 比较结论

提出的主 reference 路线是 **geometry-fitted conforming FEM supercell with twist-band
collapse**。它在固定 $\beta$ 下直接离散 current scalar volume weak eigenproblem，完全不消费
BIE layer potentials、one-cell scattering map、ordered QZ subspace、density 或 estimator。
主误差轴是 fitted FEM discretization 和 defect-image/supercell interaction，与当前 BIE/QZ
chain 的 boundary quadrature、Fourier trace、cell-map 和 QZ branch errors 不同。

该选择已通过 Skeptic method review with conditions；它不是 numerical result，也不宣称 certified
$\varepsilon_{\mathrm{ref}}$。FEM+RtR 为后备 cross-reference；PWE/MPB 只作辅助；PML、公开
benchmark 和 FSS 不作为主 reference。

M1 的 future truth contract 必须导出 gap 内全部 independently qualified branches 的有限
observed set，而不是先选一个 same-mode root。第一层只比较到该 empirical set 的 observed
distance，coverage 不充分时 fail closed；第二层 single-mode ratio 另需 frozen target-specific
estimator 或 sufficient continuous isolation。field label 相同本身不完成第二层升级。

## 总表

| ID | 方法及主要来源 | continuous match / eigenobject | 独立性 | mode identification | refinement / uncertainty | sharp interface / reproducibility | 主要风险与成本 | 决定 |
|---|---|---|---|---|---|---|---|---|
| M1 | fitted conforming FEM supercell；Fliss (2013), Giani (2013), Soussi (2005) | `HIGH`；固定 $\beta$ 直接求 $\lambda=k^2$ 与 $u$；取 $A=I$, $B=q$ 精确匹配 current transmission | `HIGH`：volume weak form + mesh + periodized finite domain；不建 BIE map，不用 QZ | independent bulk gap；全 branch inventory；defect-band twist flattening；central localization；outer-shell decay；common-core field continuation；stable reflection parity/branch label | mesh/element-order、supercell width、boundary twist、solver residual；逐支输出 $\Delta_{\mathrm{ref},j}^{\mathrm{obs}}$ 与 empirical set，均不是 bound/completeness claim | circle-fitted mesh 自然保持 sharp interface；standard FEM ecosystem 可重现 | near band edge 需要大 cell；bulk bands/band folding；coverage 可失败；Soussi theorem 未逐假设迁移到 exact current line defect | **主路线 / proposed**；`important caveat`, no blocker at method stage |
| M2 | high-order FEM + RtR transparent boundary；Fliss--Klindworth--Schmidt (2015), Klindworth (2015) | `HIGH`；同一 fixed-$\beta$ guided NEP，返回 field | `MEDIUM-HIGH`：volume FEM and RtR cell problems differ from BIE/QZ, but shares half-guide-map concept | gap + localization + branch continuation；RtR avoids Dirichlet poles | volume mesh/order、cell trace/RtR resolution、NEP tolerance；可与 M1 cross-check infinity treatment | fitted FEM handles disks；论文/论文代码合同清楚但实现复杂 | nonlinear solve and map construction costly；transparent-map numerical analysis not closed；部分 conceptual shared bias | **后备 cross-reference**；若 M1 weak confinement 成本失控则升级 |
| M3 | plane-wave/Fourier supercell, preferably public MPB；Norton--Scheichl (2013), MPB docs | `CONDITIONAL`；2-D polarization mapping正确时可求 frequency+field | `HIGH` discretization/implementation independence；与 M1 共享 supercell modeling error | defect band in independent gap；field localization/parity；twist branch | Fourier resolution、geometry subpixel/mesh、supercell width、solver tolerance | public implementation；但 discontinuous high-contrast circle limits regularity/convergence | Gibbs/factorization/formulation sensitivity；targeted solve may leak $\widehat k_h$；scalar operator mapping not frozen | **辅助 cross-check only**；不可单独定义 truth |
| M4 | fitted FEM truncated strip + PML | `CONDITIONAL`；可表示 geometry and field，但 real bound mode does not require outgoing-resonance PML | `HIGH` relative to BIE/QZ | localization, low PML energy, parameter stability | mesh, physical domain, PML thickness/profile/strength, tolerance | general FEM packages available | non-selfadjoint spectrum；PML/artificial eigenvalues；more tuning axes; risk of selecting physical-looking PML root | **排除主路线**；仅 weakly confined/leaky extension 时重开 |
| M5 | homogeneous-boundary finite strip (Dirichlet/Neumann/Robin) | `MEDIUM`；bounded eigenproblem approximates same PDE but artificial boundary is modelling change | `HIGH` | gap membership, core localization, paired-boundary stability | mesh, strip width, boundary closure | simple and fitted | ordinary gap Galerkin may pollute; no general bracketing; outer-boundary roots can mimic localized modes | **保留廉价 diagnostic**；不作 sole reference |
| M6 | FSS/multipole infinite-cladding method；Wilcox et al. (2005) | `POTENTIALLY HIGH` for cylindrical line defects; exact current parameter implementation unverified | `MEDIUM`：different fictitious-source formulation, but still uses quasiperiodic response/Bloch modes | localization and branch continuation | multipole/source order, quadrature/Bloch averaging, tolerance | no current public exact-parameter implementation found | full formulation/access/implementation burden; shared modal and cylinder-scattering bias with current chain unclear | **实质后备，未选** |
| M7 | exact-parameter public benchmark/data | `NONE FOUND` | would be high if implementation independent | would require field/metadata, not number only | must include reference resolution/provenance | no qualifying data | all located data mismatch radius, contrast, $\beta$, polarization or normalization | **不可用** |
| M8 | same BIE/QZ chain at larger $n_{\mathrm{tot}}$, $M$ or precision | continuous target nominally same | `LOW/NONE` | same selector and same-trial diagnostics | only shared-chain refinement | existing implementation | shares all dominant bias and information; forbidden by protocol | **排除** |

## 候选详评

### M1 — fitted conforming FEM supercell

**Formulation.** 在含一条 missing column 的大型周期 cell 上，对 $x$ 边界施加独立 twist，
对 $y$ 保持 current $\beta$-quasiperiodicity；在 circle-fitted mesh 上求

$$
a_N(u,v)=\lambda_N m_N(u,v),
\qquad
a_N(u,v)=\int_{\Omega_N}\nabla u\cdot\nabla\overline v,
\qquad
m_N(u,v)=\int_{\Omega_N}q u\overline v.
$$

其 field 在 defect 周围局域时，supercell copies 的相互作用随宽度降低，defect band 对 boundary
twist 变平。Fliss (2013) 直接给 current problem family 的 gap exponential decay；Giani
(2013) 直接展示 removed-column line-defect FEM supercell eigenvalue+field；Soussi
(2005；online 2006) publisher
abstract 对 compact defects 直接报告 exponential supercell frequency convergence and wave-vector
quasi-independence。最后一步到 current exact model 是跨来源推断，不是已取得 error constant。

**Independence.** 主 matrix 由 volume bilinear forms 形成；不调用 current QP Green function、
circle density、wall Fourier trace、one-cell scattering map、QZ stable subspace 或 estimator。
geometry/material 共享是必须的 physical match，不是 shared numerical bias。

**Mode identification.** 不按离 $\widehat k_h$ 最近选 root。对宽搜索窗口内的所有 branch，先按
independent bulk gap、twist flatness、center localization、outer-shell mass decay 和 common-core
field overlap 分配 mode ID；reflection parity 和 branch continuation 作为稳定标签。若有多个 branch
同样通过，第一层全部保留；若 cluster 无法枚举则输出 `REFERENCE_SET_COVERAGE_UNRESOLVED`，
若只无法作 target-specific 区分则输出 `MODE_ID_AMBIGUOUS`。

**Uncertainty.** 报告 mesh、supercell width、twist band、solver residual 四个 observed axes，
并逐 branch 保存 observed envelope $\Delta_{\mathrm{ref},j}^{\mathrm{obs}}$。任何
monotone/exponential fit 只作 diagnostic，除非未来另有严格 theorem/constant；本轮不定义
$\varepsilon_{\mathrm{ref}}$，也不把有限 observed set 声称为 complete continuous spectrum。

**Truth contract.** 第一层对完整 frozen empirical set 形成 observed set distance；搜索域未覆盖
独立 gap 或 branch inventory 不完整时 fail closed。第二层只有在 estimator 已冻结为
target-specific，或 continuous isolation 足以把 gap-set error 等同于指定-mode error时，才允许
single-mode denominator。揭盲后的 field match 只核对 mode consistency。

**Caveats.**

- `important caveat`：目标若靠近 projected-gap edge，decay 变慢，supercell cost 可能急升；
  此时 M2 更合适。
- `important caveat`：bulk-like folded bands 必须由 localization/twist/common-core field 排除，
  不能只看 gap 中位置。
- `minor caveat`：同一 FEM family 的 h/p refinements 不是 implementation-level independence；
  公开 PWE 或 M2 可作为可选 cross-check。

### M2 — FEM + RtR transparent boundary

RtR 对 global/local Dirichlet eigenvalues 比 pure DtN 更稳健，且 bounded defect cell 不产生
supercell modeling error。它仍需 half-guide cell problems、RtR propagation operator 和 nonlinear
eigenvalue solve。相对于 current chain，它把 BIE/Nyström/QZ 换为 volume high-order FEM/RtR；
相对于 M1，它把 defect-image error 换为 transparent-map discretization error。

没有选择 M2 为首版主路线的原因不是科学不可信，而是实现/审查表面积更大，且与 current chain
共享 half-guide map/Riccati conceptual structure。若 M1 的 twist band 在可承受 refinement 下不收缩，
M2 是预先登记的最小升级，不需要改变 continuous target。

### M3 — PWE/MPB

MPB 提供 eigenfrequencies、eigenfields、resolution/mesh/tolerance 和 symmetry controls，是强
implementation-independent auxiliary route。但 current scalar operator 必须显式映射到正确 2-D
polarization；naive nearest-target solve 会产生信息泄漏；sharp high-contrast interfaces 的 Fourier
convergence 也可能慢。故 M3 可核验位置、parity 和 field shape，不单独支撑 effectivity denominator。

### M4/M5 — PML 与普通 finite strip

PML 对 resonance/leaky mode 有价值，但 current target 是 projected gap 中 real localized
eigenmode。引入 PML 会把 self-adjoint real problem变为带参数的 non-selfadjoint problem，并可能
生成 artificial roots。普通 Dirichlet strip 更便宜，却可能出现 bulk/boundary states。二者都必须
以 domain/boundary variation and localization 过滤，只适合作为 M1 的 boundary-sensitivity
diagnostic。

### M6 — FSS/multipole

FSS 处理 genuinely infinite cladding，对 near-cutoff extended modes 有吸引力；圆柱结构也合适。
但找到的 primary evidence 未给 exact current parameter implementation/data，且 quasiperiodic
response/Bloch-mode construction 与 current cell/modal machinery 的 shared bias 需专项审计。
因此公平保留为 substantive backup，不因主路线偏好而删除。

## cross-reference 组合

若未来需要比单一路线更强的经验 reference，优先级为：

1. M1 finest frozen branch collection 为主 empirical reference set；
2. M2 在同一 continuous specification 下独立求一条 branch，主要检查 infinity treatment；
3. M3 仅检查 field parity/localization 和有限有效数字，主要检查 volume discretization。

M1+M2 不是严格误差证明；M1+M3 共享 supercell modeling error；三者一致仍只能形成 stronger
empirical triangulation。任何 cross-reference configuration 都必须在揭示 current estimator 和
$\widehat k_h$ 之前冻结。

## 选择的反事实检查

- 移除最支持 M1 的单篇来源（Giani 2013）后，Fliss 2013 的 fixed-$\beta$ decay/supercell
  formulation、Soussi abstract 的 supercell convergence 和 general conforming FEM weak form 仍
  支持路线；line-defect implementation evidence 变弱，但选择不翻转。
- 移除 Fliss 2013 后，M1 无法再直接证明 current line-defect field 的 exponential decay；此时
  selection 应降级为 `METHOD SELECTION BLOCKED`。因此 Fliss 是不可替代的 continuous source。
- 若 future independent bulk computation 显示宽窗口不在 projected gap，或 twist band 不收缩，
  M1 合法失败并切换 M2；不得扩大窗口只为接近 current candidate。
