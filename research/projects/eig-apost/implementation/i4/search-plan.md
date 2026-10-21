# I4.1 文献检索与方法选择计划

状态：`FROZEN BEFORE FORMAL SEARCH`
冻结日期：2026-08-28
范围：I4.1 literature/method research；不含 experiment design、implementation 或 computation。

## 1. 精确研究问题

寻找并比较能够在不消费当前 estimator、BIE density、QZ eigenvector 或 same-trial diagnostics
的条件下，独立计算当前二维 periodic line-defect waveguide 的同一 continuous guided-mode
eigenpair $(k_*,u_*)$ 的数值方法。主 reference 至少要形成可复查的 refinement ladder 和经验
resolution assessment；若没有经证明的误差界，只能记为 $\Delta_{\mathrm{ref}}^{\mathrm{obs}}$，
不得称为 certified upper bound。

方法选择问题是：哪一条路线在 continuous-problem matching、与当前 BIE/QZ chain 的独立性、
target-mode identification、refinement 可控性、sharp-interface 适用性和可实现成本之间提供最佳
平衡，并足以支撑未来 effectivity comparison？

## 2. 必须匹配的 continuous problem

候选方法必须能够表达以下同一连续对象，而不是只复现一个接近的数字：

- 二维 scalar Helmholtz transmission problem；当前 operator 使用连续场与连续法向导数的
  transmission contract，而不是另一种 divergence-form polarization；
- 横向 $y$ 周期 $L_y=1$，固定准周期参数 $\beta=0.5$；
- lead 方向 $x$ 的周期为 $1$；左右为相同的 sharp-disk periodic leads，中心缺去一整列介质柱，
  中心空列为 $X_L=-0.5$ 到 $X_R=0.5$；
- 普通胞元的圆柱半径 $R=0.2$，背景系数为 $1$，柱内系数为 $17$，因此背景和柱内波数分别为
  $k$ 与 $\sqrt{17}k$；
- 目标是固定 $\beta$ 求正实频率 $k$ 及沿 $x$ 局域、沿 $y$ 满足 $\beta$-准周期条件的非零
  guided-mode field；谱参数换元必须明确区分 $k$ 与 $\lambda=k^2$。

若来源使用 TE/TM 名称、不同时间因子、不同准周期相位、单位胞元方向或频率归一化，必须先给出
到上述 scalar operator 的显式映射；无法映射者不能成为主 reference。当前 $k\approx1.85$ 只可
用于未来预注册的宽搜索窗口，不作为来源或方法通过标准。

## 3. 数据库与来源层级

按以下顺序检索并交叉核验：

1. 本地 `ref/ref_data/` 原文、既有 Phase 2 source files 及其 backward/forward citations；
2. DOI/Crossref、出版社正式页面、作者主页和大学或研究机构 repository；
3. arXiv、HAL 等合法 preprint/accepted-manuscript repository；
4. Web of Science/Scopus/Google Scholar/Semantic Scholar 或通用学术搜索用于发现和引用追踪；
5. 官方软件、benchmark 或项目页面只用于复现性与实现材料核验，不能替代论文中的数学主张。

证据优先级为：已取得并核验的 peer-reviewed full text；已核验的正式 preprint/AAM；只核验身份
和摘要的正式页面；其他 grey literature。搜索摘要只用于发现，不作为原文证据。

## 4. Query families

检索至少覆盖以下 query families，并记录实际字符串和平台：

```text
(photonic crystal waveguide OR periodic line defect) AND
  (guided mode OR defect mode) AND
  (finite element OR FEM) AND (eigenvalue OR eigenmode)

(periodic waveguide OR photonic crystal waveguide) AND
  (Dirichlet-to-Neumann OR transparent boundary OR exact boundary condition) AND
  (guided mode OR eigenvalue) AND (finite element OR spectral element)

(photonic crystal waveguide OR periodic line defect) AND
  (PML OR perfectly matched layer OR supercell OR truncated strip) AND
  (eigenvalue convergence OR guided mode)

(photonic crystal waveguide OR line defect) AND
  (plane wave expansion OR spectral method OR Fourier) AND
  (guided mode OR eigenmode) AND (convergence OR benchmark)

(guided mode eigenvalue) AND (adaptive finite element OR a posteriori OR verified eigenvalue)

(periodic waveguide) AND (mode identification OR localization OR symmetry OR decay) AND
  (eigensolver OR eigenfunction)
```

补充定向追踪：Fliss (2013) 的 FEM/DtN guided-mode 方法、transparent-boundary/RtR/PML 后续；
Huang--Lu--Li 类 line-defect benchmark 的独立复现；Soussi 的 supercell convergence；以及明确
报告失败、spectral pollution、PML spurious modes、supercell band folding 或 sharp-interface
收敛限制的来源。

## 5. 纳入与排除标准

### 纳入

- 直接求 periodic/photonic-crystal waveguide guided eigenvalue/eigenfunction，或提供可严谨迁移的
  transparent-boundary/supercell eigenmethod；
- 数学对象、边界处理、离散空间和 eigenvalue parameter 足够明确；
- 至少能独立改变 mesh、横向截断域、supercell width、PML/DtN 参数或 solver tolerance 中的一项；
- 对 sharp material interfaces 有明确处理，或可在 fitted mesh/weak form 中自然表达；
- 正文提供足以核验方法和限制的原文位置；
- benchmark/data 若要成为主 reference，必须完全匹配参数和归一化并提供 field 或独立 mode
  identification 信息。

### 排除或降级

- 同一 BIE/QZ chain 仅提高 $n_{\mathrm{tot}}$、$M$、proxy 或 arithmetic precision；
- 只给约 $1.85$ 的位置一致，而没有 field、mode identity 或 refinement assessment；
- 固定频率求 Bloch wavenumber 且无法可靠反解为固定 $\beta$ 求 $k$；
- smooth Gaussian profile、不同半径/contrast/缺陷、不同 polarization 或不同 phase convention，
  且无法精确映射到当前 continuous problem；
- 只给有限 strip/supercell root，却不检查 transverse localization、domain/PML truncation 或
  spectral pollution；
- 没有误差界，也无法形成可信 refinement/resolution ladder；此类结果最多作辅助位置核验；
- 搜索摘要、二手综述转述或无法确认存在性的引用。

## 6. Independent-reference 标准

主 reference 必须同时满足：

1. continuous PDE、材料、几何、准周期和频率归一化完全匹配；
2. 不使用 current BIE layer potentials、one-cell scattering map、ordered QZ、BIE density、
   estimator trial 或其阈值；
3. 主要数值表述和主要误差源不同，例如 fitted FEM volume discretization 加独立 transparent
   boundary/PML/domain truncation；
4. 独立实现，且 future configuration 不由当前 estimator 或 candidate-reference 差异调参；
5. 能产生 eigenvalue 和 field，并以预注册的 localization、symmetry、decay、branch continuation
   或 field overlap 识别目标 mode；不得选择最接近 $\widehat k_h$ 的 root；
6. 能通过至少两个相互独立的 refinement axes 评估 reference resolution，或由一条主方法加一条
   不同共享偏差的 cross-reference 形成三角核验。

与当前链共享物理模型不是共享偏差；共享 BIE kernel、QZ subspace、density、root selector 或
estimator-derived tuning 才构成信息泄漏或方法不独立。

## 7. 原文核验规则

- 每一关键方法主张回到 full text，记录 PDF 页码、section、equation、theorem、algorithm、table
  或 figure；搜索摘要和引用片段不得替代；
- DOI、题名、作者、venue、年份由 DOI/publisher/author/institutional page 至少一处权威元数据核验；
- 区分“来源直接支持”“跨来源推断”“当前未验证”；跨来源推断必须列出参与来源和推理缺口；
- 对方法是否求 field、是否处理 sharp interface、是否有收敛/误差结果、是否原生固定 $\beta$
  逐项核验，不从标题推断；
- 引用到 theorem 或 convergence 时核对全部适用假设，不把 forced-scattering 结果自动迁移为
  guided-eigenvalue theorem；
- 新 PDF 下载后先核验 title page/metadata，再进入 `sources.md` 和任何主张。

## 8. Lawful public-full-text 规则

- 只下载 publisher open access、作者主页、institutional repository、arXiv/HAL 或其他明确合法的
  public full text；不绕过 paywall，不保存来源不明副本；
- 新 PDF 保存为 `ref/ref_data/<FirstAuthorSurname><PublicationYear>.pdf`，重名用 `a`、`b`；
- 新增、重命名或移除 PDF 时同步按第一作者姓氏、年份排序维护 `ref/README.md` 和
  `ref/reference.bib`；不猜测缺失元数据；
- 无公开全文时只记录 DOI/权威页面、访问障碍和方法选择影响；无法核验原文内容时明确降级；
- 临时下载、文本提取和页面渲染只放 `tmp/`，不作为权威来源。

## 9. 主动寻找反例与失败证据

每个实质候选至少执行一组反向检索：

- `method + spurious eigenvalues / spectral pollution / failure / limitation`；
- FEM/PML：PML eigenvalue pollution、complex spurious modes、domain-truncation sensitivity；
- supercell：band folding、defect-band contamination、slow exponential localization；
- plane-wave/spectral：Gibbs/sharp-interface convergence、Fourier factorization、mode mixing；
- DtN/TBC：truncation resonance、exceptional frequencies、non-selfadjoint discretization；
- mode matching：branch crossing、symmetry switching、nearest-root misidentification。

若反面证据否定预期路线，保留在 `methods.md` 并相应降级；不得为支持预期路线省略。

## 10. 搜索停止条件

正式检索在同时满足下列条件时停止：

1. 至少覆盖 FEM truncated strip/supercell、FEM+DtN/TBC/RtR/PML、plane-wave/spectral、公开
   benchmark/data 和双方法 cross-reference 五个方法族；
2. `methods.md` 至少保留三条实质候选，并对每条给出主来源、matching、independence、mode
   identification、refinement、uncertainty、共享偏差、成本和失败证据；
3. 至少一条路线有足够原文证据写出 future implementable mathematical formulation；若没有，
   明确输出 `DRAFT / METHOD SELECTION BLOCKED`；
4. backward/forward citation chasing 与近五年更新检索各完成一轮，新增查询连续两轮不再产生
   会改变主选择或 blocker 分类的实质方法；
5. 关键 paywall/全文缺口及其影响已记录，所有引用身份已核验，合法公开 PDF 已完成索引维护；
6. 对最终候选完成一次 confirmation-bias audit：移除最支持的单篇来源后，方法选择仍能由其余
   原文和数学论证支撑，或明确降级为 blocked。

该停止条件只结束文献与方法研究，不授权 `design-4-1.md`、代码、数值实验或 effectivity 结论。
