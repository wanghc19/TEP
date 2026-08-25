# I0 manufactured NEP archive

## 阶段定位和状态

I0 是 manufactured nonlinear eigenvalue problem 的 root-and-correction 原型。历史 verdict
是窄范围 `GO / conditional-empirical`：它验证有限维数值算法，不验证 BIE、DtN 或物理
guided mode。当前仍可作为 root/correction 算法单元测试，但不支配现行物理路线。

## 文件

- [[research/projects/eig-apost/implementation/archive/i0-manufactured/design|design.md]]：
  冻结解析可解的 $2\times2$ 非正规 NEP hierarchy、root qualification 和 correction 定义。
- [[research/projects/eig-apost/implementation/archive/i0-manufactured/experiment_plan|experiment_plan.md]]：
  保存预注册参数、数值门、负例、产物合同和复现步骤。
- [[research/projects/eig-apost/implementation/archive/i0-manufactured/nep-review|nep-review.md]]：
  保存实施前后 Skeptic 审查及原 verdict。

## 实验产物入口

- 统一入口：[[test/README#I0-NEP-V1|I0-NEP-V1 manufactured NEP experiment]]。
- 当前物理路径、入口函数和权威报告只在统一实验索引维护。

## 复用和替代关系

contour count、bordered Newton、左右向量投影和负例门仍可复用为算法测试。I0 没有被另一个
算法原型否定，但它不再承担物理方法验证；真实问题由 PDE-defined DtN 和连续
$\mathcal F(k)$ 路线承接。
