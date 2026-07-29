# Phase 2b search log

## 2026-07-26 — Gate initialization

- 重新读取仓库根目录与 `research/AGENTS.md`，确认 Markdown 数学环境与 `ref/ref_data/` 保存规则。
- 复核 [[research/projects/eig-apost/phase2-sources/search-plan|Phase 2 search plan]]、
  [[research/projects/eig-apost/phase2-sources/search-log|Phase 2 search log]] 和
  [[research/projects/eig-apost/phase3-analysis/p-paper|publication route]]。
- 判定 Phase 2 原检索以 DtN 定义、BIE 接口和 NEP 工具可行性为中心，没有按 C1--C5
  的完整交叉执行创新性排除检索。
- 冻结本阶段的 search-bounded question、claim decomposition、inclusion/exclusion 和
  `PASS / PASS WITH CONDITIONS / REVISE / STOP` 判据。
- 筛选计数从 Phase 2b 的 gate-relevant unique records 重新开始，不与 Phase 2 的 40 条
  记录合并；搜索引擎不稳定的 raw hit totals 不纳入计数。

## 2026-07-26 — First targeted pass

执行的 exact/near-exact query families 包括：

```text
"line defect" photonic crystal "a posteriori error estimator" eigenvalue
"guided mode" "a posteriori error" eigenvalue DtN periodic waveguide
"recursive doubling" eigenvalue error estimator photonic crystal defect mode
"boundary integral" DtN "eigenvalue error" photonic crystal waveguide
"domain error truncation" guided modes optical fibers eigenvalue
"dual-weighted residual" optical fiber eigenvalue estimator PML
```

并围绕 Fliss (2013)、Li--Lu (2007)、Giani (2013)、Engström et al. (2016)、Yu et al.
(2022) 做题名、作者、DOI 和术语变体检索。首轮结果：

- 没有发现一篇已核验来源同时覆盖 C1--C5。
- Giani (2013) 与 Engström et al. (2016) 使“photonic-crystal eigenvalue estimator”不再
  具有创新性；Gopalakrishnan et al. (2025) 进一步覆盖 optical guided/leaky mode 的
  DWR eigenvalue estimator 和 independent-reference verification。
- Li--Lu (2007) 覆盖 point-defect DtN NEP、$\sigma_{\min}$ 扫描和 rings-convergence；
  Yu et al. (2022) 覆盖 BIE unit-cell map、semi-waveguide NtD、Riccati 和 recursive
  doubling。两者分别逼近候选路线的 spectral side 与 half-guide computational side。
- Boureghda et al. (2022) 的摘要表明 guided-mode propagation constant 的 domain
  truncation error 已有分析，必须完成全文核验。
- `ref/ref_data/Li2007.pdf`、`ref/ref_data/Yu2022.pdf` 和 `ref/ref_data/Gopalakrishnan2025.pdf` 已从合法公开来源
  下载并核验身份。Giani 与 Engström 的机构 PDF endpoint 返回 HTTP 403；当前只保留
  authoritative metadata/abstract 证据，不写入伪 PDF。

## Screening counts

- Gate-relevant unique records newly identified: `7`
- Deduplicated title/abstract screened: `7`
- Full texts or authoritative primary records checked: `6`
- Core/near-neighbor retained in the claim matrix: `6`
- Verification queue only: `1`
- Excluded after full-text check: `0`

计数中的 7 条为 Li (2007)、Giani (2012)、Giani (2013)、Engström et al. (2016)、
Yu et al. (2022)、Boureghda et al. (2022) 和 Gopalakrishnan et al. (2025)。Giani (2012)
目前只进入 verification queue，尚未进入 claim matrix。

## 2026-07-26 — Full-text closure and citation chasing

### 新增全文核验

- [[ref/ref_data/Giani2013.pdf|Giani2013.pdf]]：确认 residual estimator、eigenvalue reliability、
  effectivity 和 line-defect supercell example；估计对象不是非周期方向截断误差。
- [[ref/ref_data/Engstrom2016.pdf|Engstrom2016.pdf]]：确认 quadratic Fredholm operator
  function 的 residual/DWR estimator、左右量与 effectivity；应用是周期单胞中固定
  频率求 Bloch wavevector，不是 line-defect half-guide DtN。
- [[ref/ref_data/Boureghda2022.pdf|Boureghda2022.pdf]]：确认圆形 exact DtN 到 local Robin
  approximation 的 guided eigenvalue/eigenspace 指数型先验界；不是可计算后验量。
- [[ref/ref_data/Choutri2008.pdf|Choutri2008.pdf]]：确认上述 optical-fiber domain-truncation
  谱误差路线的早期短文与指数型先验估计。
- [[ref/ref_data/Xi2024.pdf|Xi2024.pdf]]：确认 DtN Fourier truncation 与 FEM approximation
  到 holomorphic resonance NEP eigenvalue error 的先验传递。
- [[ref/ref_data/Lin2025.pdf|Lin2025.pdf]]：确认周期 scattering BVP 中包含 DtN tail 的可计算
  a posteriori estimator。
- [[ref/ref_data/Klindworth2015.pdf|Klindworth2015.pdf]]：确认 161 页博士论文中的 DtN/RtR
  高阶 FEM、Newton/path-following 与 reference comparisons；结论明确把透明边界数值
  分析和离散 NEP 渐近收敛证明列为未完成工作。

所有需要且可合法取得的上述全文已保存到 `ref/ref_data/`，并同步更新 `ref/README.md` 和
`ref/reference.bib`。

### Backward and forward chasing

- 以 Fliss (2013)、Fliss--Klindworth--Schmidt (2015)、Klindworth (2015)、Li--Lu
  (2007)、Yu et al. (2022)、Giani (2013)、Engström et al. (2016)、Choutri (2008)、
  Boureghda et al. (2022) 和 Gopalakrishnan et al. (2025) 为种子，执行题名/DOI、引用
  链与 2024--2026 术语更新检索。
- 新的最接近记录包括 Marletta (2004)、Xi--Gong--Sun (2024)、Lin--Lv (2025)、
  Petropoulos--Turc (2025) 和 Leclerc et al. (2026)。它们分别覆盖 exterior DtN 谱
  逼近、DtN-truncated resonance NEP、periodic scattering posterior DtN term、BIE
  half-array Riccati，以及 open-waveguide approximate boundary eigenproblem。
- 未发现单篇论文或同一研究系列覆盖 C1--C5 完整链。最窄未被覆盖的环节仍是
  fixed-$\beta$ line-defect BIE NEP 中 numerical half-guide DtN truncation 到 $k$-shift
  的 computable estimator 与 simple-root effectivity。
- Bonnet-Ben Dhia--Gmati (1995)、Djellouli et al. (2000) 和 Leclerc et al. (2026) 仍为
  全文访问条件；前两篇的主要路线已被 Choutri (2008) 与 Boureghda et al. (2022)
  原文复述或扩展，Leclerc 的 HAL manuscript 处于 embargo。

## Cumulative screening counts

- Gate-relevant unique records identified: `19`
- Local original full texts verified: `12`
- Publisher full or primary texts verified: `3`
- Authoritative abstract/metadata only: `4`
- Core/near-neighbor records retained in the claim matrix: `15`
- Context or verification-only records: `4`

19 条记录由第一轮 7 条，以及 Fliss (2013)、Fliss--Klindworth--Schmidt (2015)、
Klindworth (2015)、Choutri (2008)、Bonnet-Ben Dhia--Gmati (1995)、Djellouli et al.
(2000)、Marletta (2004)、Xi--Gong--Sun (2024)、Lin--Lv (2025)、一篇 2026 periodic
scattering update、Leclerc et al. (2026) 和 Petropoulos--Turc (2025) 构成。详细纳入
逻辑和 verdict 见 [[research/projects/eig-apost/phase2b-novelty/r-gate|r-gate]]。

## 2026-07-27 — User-supplied precursor full-text closure

- 用户补入 Bonnet-Ben Dhia--Gmati (1995) 与 Djellouli et al. (2000) 全文。题名页、
  页数、作者、venue、年份、DOI 和正文均已核验；文件按仓库规则规范为
  [[ref/ref_data/Bonnet1995.pdf|Bonnet1995.pdf]] 与
  [[ref/ref_data/Djellouli2000.pdf|Djellouli2000.pdf]]。
- Bonnet-Ben Dhia--Gmati (1995) 的 PDF p. 13, Theorem 6.4 证明 exact Fourier
  boundary operator 只保留 $|p|\leq N$ 后，非线性 guided eigenvalues 对任意
  $s>0$ 满足 $0\leq\lambda_m-\lambda_m^N\leq C/N^{2s}$。该结果把一般 C4
  novelty 进一步阻断为先验谱逼近；它不提供可从本次计算得到的 $C$、posterior
  estimator、projected correction 或 effectivity。
- Djellouli et al. (2000) 明确把 local Robin artificial condition 解释为圆边界 exact
  DtN 的近似，并将 FEM propagation constants 与 circular step-index 解析 dispersion
  curves 及既有文献值比较；它提供 C6 reference-validation 先例，但没有 boundary
  truncation posterior estimator。
- 两篇来源已加入 claim matrix。gate 仍为 `PASS WITH CONDITIONS`，但可辩护 C4 必须
  明确写成 periodic half-guide numerical DtN error 的 **computable posterior**
  $k$-shift estimator，不能写成一般 boundary-truncation eigenvalue estimate。

### Updated cumulative counts

- Gate-relevant unique records identified: `19`
- Local original full texts verified: `14`
- Publisher full or primary texts verified: `3`
- Authoritative abstract/metadata only: `2`
- Core/near-neighbor records retained in the claim matrix: `17`
- Context or verification-only records: `2`

当前只剩 Leclerc et al. (2026) 的 HAL manuscript 因 embargo 尚无公开全文。
