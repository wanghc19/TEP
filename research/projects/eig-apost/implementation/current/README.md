# Current implementation guidance

## 状态与范围

当前为 `METHOD_RECONSTRUCTION / I4_NUMERICS_PAUSED`。本目录没有新的 implementation
design：OP-M0-1--OP-M0-4 尚未关闭，因此本轮不创建 $A_{\mathrm{def}}$、DtN
discretization、locator 或 root-isolation 的设计空壳。

当前数学权威是
[[research/projects/eig-apost/phase4-report/method.tex|continuous DtN/BIE method]]；当前实现
阻塞项和恢复顺序只在
[[research/projects/eig-apost/implementation/open-problems#M0|M0 ledger]] 维护。项目级状态
以 [[research/projects/eig-apost/STATUS|STATUS]] 为准。

## 当前允许复用的历史证据

归档中的 center BIE interface、Ewald reference、layer-action qualification、Fourier trace
screen 和 provenance 机制可以作为未来设计的输入证据，但必须经新的 theory-to-code map
重新引用。它们不能自行恢复旧 coupling、旧 $A_{\mathrm{def}}$ 或任何 root gate。

历史材料索引见
[[research/projects/eig-apost/implementation/archive/README|implementation archive]]；符号与
代码对象见 [[research/projects/eig-apost/implementation/SYMBOL|SYMBOL.md]]。
