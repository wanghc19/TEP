# 决定

## 2026-11-04 新建项目（用户）

- 方法从 numerical-directions 的探索中独立成项目 `research/projects/fem-goerisch/`。已有证明、报告和实验留在原处，这里只链接。
- 代码暂时放在 `test/fem-goerisch/`，不新建共享包；流程稳定、准备发布时再建。
- 下一方向是稳健性：用参数族（缺陷强度使导模靠近带边、第二个导模进入窗口、相隔几胞的两个缺陷、第二个导模恰在窗口外、几何变化）画余量随参数的曲线；反例用两个不相交的一阶区间 $I_1$（命题 5，不依赖 (H)）来确认，此时计数为 2，(H) 不成立。先用浮点 FEM 与 BIE 筛选。只改芯区而引线和窗口不变时，(A)、(B)、(C) 可复用，只需重做 (D) 和 $q$、$J$ 积分。
- 第一步只做代码清单；参数族的设计暂不开始。

## 2026-11-04 (H) 分两种算法交付（用户）

- 常规计算以 (H) 为前提，每个例子做 (H) 的浮点检查，并报告余量；结果写成"在 (H) 下截断误差意义下可靠"，注明 (H) 只经过浮点检查。不依赖 (H) 的一阶区间 $I_1$（命题 5）照常给出。
- 另外交付一个严格验证 (H) 的算法，即参数化的 (A)–(D)。只在需要时运行，例如论文里的代表性例子。
- 理由：(A)、(B)、(C) 依赖引线、$\beta$ 和窗口，只改 $\beta$ 也要全部重算；按已有记录约 55 分钟，不能每例都做。BIE 只给包含界，不给计数上界，替代不了 (H) 的认证（见 [[research/explorations/numerical-directions/isolation-survey|isolation-survey]] 第 6 节），只适合作浮点交叉检查。

## 2026-11-04 目录分类（用户）

顶层只放 README、STATUS、DECISIONS、open-problems；其余文件按类型放进 `theory/`、`implementation/`、`literature/`，规则见 README 的"约定"。`code-inventory.md` 已移入 `implementation/`。
