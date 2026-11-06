# bie-siam：BIE 导模谱距离界论文的 SIAM（SISC）英文版

BIE = boundary integral equation（边界积分方程）；SIAM = Society for Industrial and Applied Mathematics；SISC = SIAM Journal on Scientific Computing；sm = supplementary materials（补充材料）。

内容来源是中文研究笔记 `draft/bie-enclosure/`（对外版 `main-clean.tex`），按页数预算重写成英文，不逐句翻译。正文不超过 20 页（含参考文献），证明、计入舍入的计算细节和补充表格放在补充材料里；可复核的数据与检查程序在 `release/bie-enclosure-sisc/`。

- `main.tex`：正文；`sec-*.tex` 为各节，`sec-acknowledgments.tex` 是致谢与 AI 使用声明（按 SIAM AI 政策）。
- `supplement.tex`：补充材料；`sm-*.tex` 为各部分。
- `shared.tex`：两者共用的宏包、宏、标题。
- `siamplain-nonote.bst`：`vendor/siamart_251216/siamplain.bst` 去掉 note 字段（共享 bib 的 note 记录本地 PDF 路径，不能印出）。
- `latexmkrc`：把 `vendor/siamart_251216/` 加入 TEXINPUTS，类文件不复制。
- 编译：在本目录运行 `latexmk main.tex supplement.tex`，之后运行 `latexmk -c main.tex supplement.tex`。

## 页数预算（正文，SIAM 版式）

| 节 | 内容 | 预算 | 实际 |
|---|---|---:|---:|
| 1 | 引言（含标题、摘要、贡献、与已有方法的关系） | 1.75 | 1.5 |
| 2 | 模型、本质谱、公共谱隙及其有限维判据（只给陈述） | 2.5 | 2.5 |
| 3 | 中心胞元约化、表示定理（证明进补充材料） | 1.5 | 1 |
| 4 | 离散：Rayleigh、近像分解、引线 S 矩阵与衰减子空间、$\mathsf A(k)$、行列式求根 | 2.75 | 3 |
| 5 | 实际场、跳跃、分组迹估计、谱距离定理及证明、引线尾、可靠计算依赖表 | 6 | 4 |
| 6 | 例 1 与 FEM 对照；例 2 与谱隙端点例合表；分辨率一句 | 3.75 | 3 |
| 7 | 结论 | 0.25 | 0.25 |
| — | 参考文献 | 1.5 | 2（34 条） |
| | 合计 | 20 | 17 |

取舍依据：2026-11-06 价值排序表（经理给出，用户同意按此开写）：谱距离定理、分组迹估计、引线尾、例 1 区间留在正文；公共谱隙判据、表示定理、本质谱命题只留陈述；附录 C 的包络引理、中间量表、分辨率表与计算量表进补充材料；§3.4 DtN 关系、投影能带图、行列式图、中心面板贡献图、代理拟合参数删除或进补充材料。

## 进度

- done（2026-11-06）：正文 7 节与摘要、关键词、MSC 初稿全部写完，`main.pdf` 17 页（含参考文献 34 条）；补充材料 `supplement.pdf` 13 页（证明、计入舍入的计算、补充表格）。两份均无 overfull、无未定义引用。实际页数是按各节起始页估计的。
- done：跨文档引用修复。模板自带的 xr-hyper 会把对方 PDF 文件名拼进 cleveref 的引用文字（“Proposition 2.1main.pdf”），`shared.tex` 末尾的补丁让 `@cref` 标签原样导入。
- done：第一遍记号通读。改动：Floquet 乘子 $\lambda\to\zeta$（避开能带 $\lambda_{s,n}$）；去掉 $q=\ee^{\ii\beta d}$ 的简写（与入射幅值重名），入射幅值记为 $\mathsf a$；补上 $\mathsf D_\pm,\mathsf N_\pm$ 的定义；代理源下标 $p\to i$；证明中截断函数 $\chi_R\to\chi_X$；谱半径 $\rho\to\varrho$，到能带端点的距离 $\delta\to\delta_{\mathrm e}$；例 2 “宽度在 $5$–$9\times10^{-12}$ 之间”与表中 $L_0=1$ 的 $3.09\times10^{-12}$ 不符，改为“低于 $10^{-11}$”。
- done：R2 复现包覆盖例 2 的四个点后更新表 `tab:ex2`：时间列改为复现包一次冷启动的用时（1076/1194/1353/1532 s），删去 $L_0=1.6$ 双进程脚注；$Q$ 列改为向上舍入（1.40/4.13/3.87/6.24），与表 `tab:ex1` 一致；正文“总时间增加 13%”有误（$L_0=1\to2$ 实为 42%），已改。其余数值与复现包一致。
- next：填 release 引用（R1、R2 已完成）；R3 返回后补 FEM 代价—宽度序列；再整体通读一遍（含补充材料）。
- done：作者、邮箱、机构、投稿日期改为占位（Author、author@example.com、Example University、DATE）。
- done：致谢节写入 AI 使用声明，依据 SIAM 政策 2.0 版（2026 年 5 月生效，原页 HTML 由用户存于 `tmp/`）：在 Acknowledgments 报告用途并附 “The authors assume responsibility for all content.”；政策不要求模型型号，只写 Claude 与 GPT；按政策列出的方面写定理证明、代码与实验（代码公开于 release 包）、图表、文献与文字。剩余 TODO：release 引用、作者亲自核查的内容。
- open：真实作者信息；FEM 路线的引用方式；release 包的引用方式。保留未改的轻微重名：$\tau$（密度）与 $\tau_g$（迹估计常数），$n$（密度未知数个数）与 $n(\cdot)$、$n_s$。
