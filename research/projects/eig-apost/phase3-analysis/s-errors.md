# I3.1 residual 覆盖与遗漏项

## 1. 误差对象

第一层目标是

$$
e_h^{\mathrm{gap}}
=\operatorname{dist}\bigl(\widehat k_h,
\mathcal K_{\mathrm{disc}}(A;G_\lambda)\bigr),
$$

其中 $G_\lambda\subset(0,\infty)$ 是需要针对当前模型认证的 continuous projected essential
gap，且
$\mathcal K_{\mathrm{disc}}(A;G_\lambda)
=\{\sqrt{\lambda}:\lambda\in\sigma_{\mathrm{disc}}(A)\cap G_\lambda\}$。
约定到空集的距离为 $+\infty$；只有可靠区间进入该 gap 后，第一层存在性才保证这个集合
非空。
若 $G_\lambda=(g_-,g_+)$ 且 $0<g_-<g_+$，记
$G_k=(\sqrt{g_-},\sqrt{g_+})$。
continuous residual 直接在 saved candidate 处测量重构场对连续弱特征方程的违反程度。它不先
拆成 candidate-to-finite-root 与 finite-root-to-continuum 两段。只有以后确需识别指定 mode
时，才追加 $e_h^*=|k_*-\widehat k_h|$ 的第二层目标。

## 2. 必须随指标分列的组成项

| 组成项 | 主 residual 应如何处理 |
|---|---|
| 材料子域内体方程 | 作为 volume residual 纳入 |
| 材料界面 field/flux mismatch | 作为 interface jump 或 reconstruction term 纳入 |
| 胞元接口和人工截面 | 作为 trace/flux mismatch 纳入 |
| 横向准周期条件 | 作为 boundary mismatch 纳入 |
| half-guide、Rayleigh/Fourier tail | 纳入 global cutoff residual，或在 exact-DtN 路线中单列 DtN/tail 差异 |
| field reconstruction 与 trace repair | 纳入 residual 或独立可计算 allowance |
| dual-norm Riesz solve | 报告 discretization、quadrature 和 algebraic error |
| floating-point 与 field evaluation | 用 repeat/precision 检查形成 numerical allowance |
| continuous projected essential gap | 第一层存在性需要针对当前连续模型建立并核对区间 containment；不能由 finite QZ gap 或 I2 count 替代 |
| 预注册频率分辨率 | 在查看 estimator 结果前固定 $\tau_k^{\mathrm{pre}}$ 和 $0<\rho_G^{\mathrm{pre}}<1$；可靠 $k$ 区间宽度须通过绝对门，且 $\tau_k^{\mathrm{pre}}\le\rho_G^{\mathrm{pre}}\operatorname{diam}(G_k)$，否则只保留存在性 |
| unique target identity/multiplicity | 不由 residual 大小或 gap containment 自动决定；只有需要指定 mode 时才在第二层单独处理 |

任何未计算项都必须列入 ignored errors。不能把它默认为零，也不能用原离散矩阵 residual 代替。

## 3. 内部数值证据的边界

I3.1 可以使用下列内部检查：

- field reconstruction 在 refinement 下稳定；
- residual components 的分项和总和可复算；
- Riesz space 加密时 dual-norm approximation 稳定；
- phase/scale 改变不影响 normalized indicator；
- quadrature、linear solve 和 repeat error 小于 residual signal；
- manufactured exact field 给出预期的零或已知 residual；
- 故意加入 interface jump、tail defect 或错误 candidate 时，指标能够响应。

这些检查只论证公式和实现自洽。它们不能替代 I3.2 的独立 reference，也不能从稳定平台推导
误差上界。

## 4. 共同偏差与部分 residual

若 numerical DtN、field reconstruction 和 residual evaluation 共享同一错误，内部 residual
可能很小而 $e_h^{\mathrm{gap}}$ 仍不小。因此首个设计必须标明 residual 是否真正作用于 continuous form，
还是只作用于同一离散方程。

只覆盖体方程、只覆盖 boundary samples 或只覆盖 numerical-DtN center equation 的量仍可
保存，但必须命名为 component/partial residual。它不能成为 total estimator candidate，除非
其他项已被独立控制。

## 5. 数值信号与失败条件

设计算得 $\widehat q_h$，并有同量纲数值 allowance $u_{q,h}$。至少要求：

- field norm 下界与 field-evaluation error 分离；
- residual signal 大于 quadrature、Riesz solve、linear solve 和 repeat error；
- 多个预注册 Riesz/refinement levels 没有显示未解析增长；
- 任何 tail 或 reconstruction omission 都在结果中显式可见。

若这些条件失败，输出 `CONTINUOUS_RESIDUAL_UNRESOLVED` 或 `PARTIAL_RESIDUAL_ONLY`，而不是
切换到有限根路线并把其结果改称 continuous error。

可靠 residual 形成谱区间后，还要分开报告三个逻辑门：

1. residual/field/numerical bounds 是否真正覆盖所用区间；
2. 区间是否完全位于当前连续算子的 projected essential gap；
3. 映射到正频率后的区间宽度是否不超过事前冻结的 $\tau_k^{\mathrm{pre}}$，且该绝对尺度是否
   通过事前冻结的 gap-relative 非空泛门。

第一门失败时没有 certified interval；第二门失败时不能声称 gap 内离散特征值；第三门失败时
存在性可以保留，但分辨率不足。唯一目标识别是独立的第二层升级，不得反向成为上述三门或
residual 计算的 blocker。

## 6. OPTIONAL finite component

$\delta_h^{\mathrm{loc}}$ 和 $\delta_h^{\mathrm{disc}}$ 可诊断有限矩阵局部位移或某一 refinement
分量。它们不在 residual 总量中自动相加，也不为 shared continuous bias 提供控制。只有
I3.1 或 I3.2 明确需要定位某个异常来源时才运行。

## 7. 当前状态

- 已完成：continuous residual 的目标、抽象谱结论和覆盖分类；
- 未完成：实际 field reconstruction、完整 residual formula、dual-norm computation 和
  numerical allowance；当前 sharp-disk continuous projected gap 与预注册分辨率也尚未冻结；
- 允许名称：continuous-residual estimator candidate；
- 可靠区间进入 gap 后的第一层名称：达到预注册分辨率的 continuous discrete-eigenvalue
  existence interval，或分辨率失败时的 `EXISTS_BUT_RESOLUTION_INSUFFICIENT`；
- 不允许名称：empirical eigenvalue-error estimator、certified error estimate、upper bound。
