# vendor：第三方依赖

本目录集中存放仓库用到的第三方二进制依赖。除本 README 外，目录内容都被 Git 忽略；新建工作树时需要从已有工作树复制，或按下面的命令重建。FMM = fast multipole method（快速多极子方法）；MEX = MATLAB executable（MATLAB 可调用的编译扩展）。

| 子目录 | 内容 | 来源与重建 |
|---|---|---|
| `fmm2d/` | FMM2D 源码与 macOS arm64 构建；MATLAB 接口在 `fmm2d/matlab/`（`hfmm2d.m`、`fmm2d.mexmaca64`） | `flatironinstitute/fmm2d` 提交 `550dae5b77b1e006c8ffae37fc832f8c2b536871`，Apache-2.0；构建步骤见 `test/i8/fmm-v1/README.md`（其中的 `vendor/fmm2d` 即本目录的 `fmm2d/`） |
| `python/` | python-flint 0.9.0（CPython 3.14，macOS arm64） | `python -m pip install --no-cache-dir --no-deps --target vendor/python python-flint==0.9.0` |

NumPy 与 SciPy 不在本目录：用 Conda 环境 `octave` 里的 NumPy 2.5.4、SciPy 1.18.1。该环境也装有同版本的 python-flint；`python/` 是它的备份，供把本目录放进 `PYTHONPATH` 的旧实验使用。

`Faddeeva_erfc.mexmaca64`（复数 erfc 的 MEX）放在仓库根目录，因为调用它的脚本只把根目录加入 MATLAB 路径。它同样被 Git 忽略。

旧路径保留为指向本目录的相对符号链接，原有脚本和复现命令不用改：

- `test/i8/fmm-v1/vendor/fmm2d` → `vendor/fmm2d`
- `test/i6/resolvent-v3/vendor` → `vendor/python`
- `test/spectral-counting/gap-v1/vendor` → `vendor/python`

新的实验应直接引用本目录，例如 `--fmm-root <仓库根>/vendor/fmm2d/matlab`，或 `PYTHONPATH=<仓库根>/vendor/python`。
