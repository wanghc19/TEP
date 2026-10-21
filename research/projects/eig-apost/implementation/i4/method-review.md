# I4.1 独立 reference 方法审查

状态：`SKEPTIC RE-REVIEW COMPLETE / PASS WITH CONDITIONS`

审查对象：[[research/projects/eig-apost/implementation/i4/method-4-1|method-4-1]] 及其
[[research/projects/eig-apost/implementation/i4/sources|source matrix]]、
[[research/projects/eig-apost/implementation/i4/methods|candidate comparison]] 和
[[research/projects/eig-apost/implementation/i4/search-log|search log]]。

审查历史：初审 verdict 为 `REVISE`，唯一 blocker 是 I3 的 set-distance target 被单一
same-mode denominator 替代。Researcher 已按限定范围完成纯文本修订；本文件记录同一 Skeptic
的复审结论。初审 blocker 的内容保留为下方 resolution record，不再是 unresolved finding。

`[DA-DECISION: Score 5/5 | ACTION: Concede | REASON: 修订完整分开 observed finite-set 与 target-specific truth contracts，并对 coverage、field label 和 continuous truth 全部 fail closed。]`

## A. Audit frame

| 项目 | 复审框架 |
|---|---|
| 精确问题 | 修订稿是否消除了 set-distance estimator 与 single-mode reference denominator 的混用，同时不把 empirical coverage/resolution 升格为 continuous truth？ |
| claimed contribution | 选择 geometry-fitted conforming FEM supercell，独立生成 broad gap/window 内的 qualified branch collection，供未来 observed-reference comparison 使用。 |
| 当前阶段 | literature/method research；不是 experiment design、实现、运行或数值结果。 |
| intended output | 面向工程数值研究的 independent-reference 方法合同；本轮不要求 theorem-level reference enclosure。 |
| 成功标准 | complete finite empirical collection、coverage failure、observed set distance、target-specific upgrade 和 field check 的职责不可混用；修订不产生新的真实 blocker。 |
| 权威 | [[research/projects/eig-apost/phase4-report/method|continuous method]]、[[research/projects/eig-apost/implementation/i3/README|I3 guide]]、[[research/projects/eig-apost/implementation/ROADMAP|ROADMAP]] 高于本轮方法稿。 |

复审重点检查了 method Sections 1、4、6、8--11，并核对 `sources.md`、`search-log.md` 和
`methods.md` 中与初审意见直接相关的同步修订。没有重开候选方法选择或文献检索。

## B. Final verdict

**Verdict：`PASS WITH CONDITIONS`。Confidence：high。**

没有 unresolved blocker。修订稿已经把第一层定义为到完整 frozen **finite empirical set**
$\mathcal K_{\mathrm{ref}}^{\mathrm{obs}}$ 的 observed distance，并明确它不等于到 continuous
gap-discrete spectrum 的距离；搜索域、branch inventory 或 resolution coverage 不充分时均
fail closed。single-mode denominator 只在 estimator 已预先冻结为 target-specific，或另有
continuous isolation 时可用；揭盲后的 field label 只提供 mode consistency，不能自动升级 target。
因此初审的 target mismatch 已解决，M1 可通过方法门并在另行授权后进入 future design。

`PASS WITH CONDITIONS` 只反映 empirical reference 的固有限制：未来必须预注册并执行多轴
resolution/coverage gate；它不授权现在创建 `design-4-1.md`、实现或实验。

## C. Strongest challenge on re-review

初审最强反例是：窗口内两个 qualified branches 中，field-matched branch 并非离
$\widehat k_h$ 最近者，因而 $|\widehat k_h-k_{\mathrm{ref},*}|$ 不能替代 I3 的 set distance。
修订稿现在让所有 qualified branches 进入 $\mathcal K_{\mathrm{ref}}^{\mathrm{obs}}$，第一层直接对
该集合取距离；无法枚举 cluster 或覆盖完整 gap 时输出
`REFERENCE_SET_COVERAGE_UNRESOLVED`。第二层另需冻结的 target-specific estimator 或 continuous
isolation。该反例因此不再使 effectivity contract 失真。

修订后最强剩余风险是所有末级变化同时处于共同 pre-asymptotic bias 区间。文稿已把这一路径
明确降级为 empirical sensitivity，并允许 `REFERENCE_RESOLUTION_UNRESOLVED`；它限制未来结论
强度，但不是当前方法选择 blocker。

## D. Findings and resolution

### 1. `BLOCKER — RESOLVED`：set-distance 与 target-specific truth contract

- **Location：** method Sections 1、4、6、9--11；同步见
  [[research/projects/eig-apost/implementation/i4/methods#M1 — fitted conforming FEM supercell|M1 comparison]]。
- **Resolution evidence：**
  - Section 1 明确 collection 包含所有 independently qualified branches，并声明有限 observed set
    不自动等于 continuous spectrum；
  - Section 4 禁止在冻结前按 $\widehat k_h$ 或其 field 选择单根；
  - Section 6 要求 broad window 覆盖独立 target gap、导出全 branch/cluster coverage ledger，且
    明确 empirical set 没有 certified completeness；
  - Section 9 分别定义 $d_{\mathrm{set}}^{\mathrm{obs}}$ 与可选
    $e_*^{\mathrm{obs}}$，并为 estimator truth-target tag、coverage、resolution 和 target upgrade
    设置独立 fail-closed states；
  - Sections 10--11 把这些 states 和数据职责映射到 future modules，没有隐藏回单根 workflow。
- **Decision：** 初审反例已被合同本身排除。field match 只作 consistency check，既不证明最近连续
  谱点，也不把 set estimator 升格为 target-specific estimator。

### 2. `IMPORTANT CAVEAT — OPEN / NON-BLOCKING`：observed resolution 仍非 error bound

- **Location：** method Sections 7--9。
- **Evidence：** $\Delta_{\mathrm{ref},j}^{\mathrm{obs}}$ 只汇总末级 FEM、supercell、twist 和
  algebraic changes；没有 current-model theorem、verified constants 或 directed arithmetic。
- **Consequence：** future ratio 只能称为 against the observed finite reference set，不能称为
  continuous truth、confidence interval、certified enclosure 或 certified effectivity。
- **Why non-blocking：** method 已明示禁止
  $|k_{*,j}-k_{f,j}|\le\Delta_{\mathrm{ref},j}^{\mathrm{obs}}$，并在 resolution 不可解释时 fail
  closed；这正是用户允许的 empirical reference claim boundary。
- **Future condition：** 另行授权的 design 必须冻结至少 FEM 与 supercell/twist 两条独立 refinement
  axes、branch-wise ledger、coverage rule 和 `REFERENCE_RESOLUTION_UNRESOLVED` 触发规则。

### 3. `MINOR CAVEAT — RESOLVED`：来源元数据与 query count

- Nannen--Wess DOI 已更正为 `10.1007/s10543-018-0694-0`；
- Cancès--Ehrlacher--Maday 已更正为 *SIAM J. Numer. Anal.* 50(6), 3016--3035 (2012)；
- Soussi 统一采用 SIAM print year 2005，并明确 Crossref online year 2006；
- `search-log.md` 的外部 queries 为 32 条：family A/B/C/D、citation update、metadata blocks
  分别为 $4+8+4+4+8+4=32$；method C10 已同步为 `32-query scoped log`。

这些更正没有新增 query、下载、内容主张或方法证据。

## E. Implementation audit

本轮没有 implementation、code、experiment design 或 numerical output。method Section 11 只给出
theory-to-future-code responsibility map，并保持 immutable reference export 前不得导入 BIE/QZ
artifact 的隔离边界；没有发现修订引入 specification-to-code claim。

## F. What survived

1. continuous problem 仍与 current authority 一致：$A=I$、$B=q$、$\beta=0.5$、sharp disks、
   missing column、$\lambda=k^2$，且不混入另一 polarization。
2. M1 的 volume conforming FEM/supercell formulation 与 current BIE/Nyström/one-cell map/QZ chain
   具有实质 numerical independence。
3. nearest-$\widehat k_h$ selection 禁令、独立 projected gap、localization、tail、twist collapse、
   parity 和 common-core continuation 均保留。
4. information blinding 与 immutable export 顺序保留；revealed field 只用于 mode consistency。
5. empirical uncertainty 的措辞和合法失败状态没有被修订削弱。
6. 候选比较仍公平保留 RtR、PWE/MPB、PML、finite strip 和 FSS 等路线及其反面证据。
7. 文稿没有冻结 mesh、twist samples、solver、tolerance、attempt 或运行命令。

## G. Minimal resolution and next gate

当前方法审查无需进一步修订、检索、证明或实验。若未来另行授权 `design-4-1.md`，其最小 gate 是
把已经通过的方法合同转成预注册的 coverage、branch inventory、multi-axis refinement、truth-target
tag 和 fail-closed acceptance rules。任何未来结果若只通过位置或 field 一致性，而 coverage 或
resolution gate 未通过，均不得报告 effectivity。

## H. Open-problem handoff

本表只供主 agent 合并到既有 ledger；Skeptic 不修改 ledger。

| Stage | Category | Item | Blocking scope | Cheapest next check | Suggested status |
|---|---|---|---|---|---|
| I4.1 method | `BLOCKER — RESOLVED` | set-distance 与 single-mode denominator 曾被混用 | 不再阻止方法门；不得在未来删除两层 contract | future review 检查 design 是否逐项实现 Sections 6、8--11 | `RESOLVED` |
| I4.1 future design | `IMPORTANT CAVEAT` | $\Delta_{\mathrm{ref}}^{\mathrm{obs}}$ 可能遗漏共同 pre-asymptotic bias | 限制 empirical reference 强度；不阻止进入 future design | 预注册至少两条 refinement axes 与 fail-closed resolution rule | `SCHEDULED` |
| I4.1 sources | `MINOR CAVEAT — RESOLVED` | DOI/year/query-count identity | 无 blocking scope | 保持当前更正，不需新增检索 | `RESOLVED` |

最终结论：`PASS WITH CONDITIONS`；没有 unresolved blocker。I4.1 方法研究可以在此停止，未来
design、实现和数值运行仍须单独授权。
