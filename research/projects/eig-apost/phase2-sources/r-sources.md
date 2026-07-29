<!-- Phase 2 source verification matrix -->

# Source verification

状态：第一轮核心来源核验完成。

| 来源 | 存在性/元数据 | 原文级核验 | 质量与用途 | 当前决定 |
|---|---|---|---|---|
| Joly--Li--Fliss (2006) | DOI 与本地 PDF 一致 | PDF pp. 8--10, 19 视觉核验 | 同行评审；吸收半波导 DtN/Riccati 与 mixed FEM | 纳入核心定义链 |
| Coatléven (2012) | DOI 与本地 PDF 一致 | PDF pp. 8--10, 19--20 视觉核验 | 同行评审；line defect、吸收、FEM、误差边界 | 纳入核心定义链 |
| Fliss (2013) | DOI 与本地 PDF 一致 | PDF pp. 11, 13, 18--20 视觉核验 | 同行评审；目标 fixed-$\beta$ guided-mode PDE/DtN | 纳入核心目标链 |
| Yuan--Lu--Antoine (2008) | Elsevier DOI + 作者全文 | PDF pp. 10--14, 17 视觉核验 | 同行评审；BIE 构造任意截面 cell DtN | 纳入核心 BIE 链 |
| Huang--Lu--Li (2007) | 期刊信息 + 作者全文 | 定义、合并式、数值段全文定位 | 同行评审；line-defect PCW 与 published data | 纳入方法/benchmark 链 |
| Yuan--Lu (2007) | DOI + Optica + 作者全文 | 合并公式与数值验证全文定位 | 同行评审；recursive doubling | 纳入独立 reference 路线 |
| Lu--Lu (2014) | Elsevier DOI + 作者全文 | Calderón/DtN 公式全文定位 | 同行评审；direct BIE-DtN 定义与离散 | 纳入通用 BIE 机制链 |
| Petropoulos--Turc (2025) | Royal Society DOI + NJIT 元数据 | 正式摘要与 indexed text；无合法公开 PDF | 同行评审；BIE RtR + half-array Riccati 架构 | 纳入近邻架构，数值细节降为次级证据 |
| Lu--Shen--Zhang (2026) | Elsevier DOI + arXiv 记录 | 摘要/正式预览核验 | 同行评审；背景 Green 函数 BIE-TBC | 保留为替代 TBC，不并入 DtN 主链 |
| Güttel--Tisseur (2017) | Cambridge DOI + Manchester AAM | `ref/ref_data/Guettel2017.pdf`, pp. 21--24 | 权威综述；NEP condition number、backward error、一阶位移 | 纳入 estimator 核心链 |
| Moskow (2015) | AIP DOI + arXiv 作者稿 | `ref/ref_data/Moskow2015.pdf`, Theorem 4.1/Corollary 4.1 | 同行评审；compact operator NEP correction | 纳入连续理论模板 |
| Bindel--Hood (2013) | SIAM DOI + arXiv 作者稿 | `ref/ref_data/Bindel2013.pdf` 定理与方法段 | 同行评审；NEP localization/pseudospectra | 纳入辅助认证链 |
| Zhang (2023) | SIAM DOI + arXiv 作者稿 | `ref/ref_data/Zhang2023.pdf`, Theorem 14, eq. (38) | 同行评审；waveguide DtN spectral truncation 指数误差 | 纳入 tail-model 近邻链 |
| Ehrhardt--Sun--Zheng (2009) | CMS DOI + WIAS/作者全文 | `ref/ref_data/Ehrhardt2009.pdf`, pp. 7--8, 15 视觉核验 | 同行评审；finite-tail StS、doubling、stop-band convergence | 纳入首版 DtN hierarchy 核心链 |

## 尚需补齐

- Petropoulos--Turc 的穿透介质扩展是否已有后续/先行论文。
- unit-cell BIE map 的离散误差如何在 Riccati 解中放大，尤其与稳定/不稳定谱分离的关系。
- 当前 BIE--DtN operator family 是否满足 Moskow 型 compactness、adjoint convergence 和
  derivative convergence；这不是文献核验本身能自动给出的。
- Huang--Lu--Li 参考例是否存在更高精度复现数据或公开代码。
- Petropoulos--Turc 是否会出现可合法保存的 accepted manuscript；当前 publisher
  full text 为 closed access，不在 `ref/ref_data/` 伪造或保留 HTML 响应。

## 本地全文存放

本轮新下载且继续使用的全文已按 `research/AGENTS.md` 统一存入 `ref/ref_data/`。
证据卡不得再把 `research/tmp/pdfs/` 中的临时提取或渲染文件作为正式来源。
