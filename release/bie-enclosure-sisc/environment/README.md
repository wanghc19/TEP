# Requirements and third-party components

Tested: Apple M3 Pro (5 performance and 6 efficiency cores), 18 GiB RAM, macOS 14.8.7, MATLAB R2023b (23.2.0.2365128). The MATLAB stages use base MATLAB linear algebra, including `svd`, `qz`, `ordqz`, `besselh` and `interpft`; no Parallel Computing Toolbox is used. The resource monitor requires POSIX `ps` and process groups. Python workers use `fork`.

Python 3.14.4; python-flint 0.9.0; FLINT 3.6.0; NumPy 2.5.4; SciPy 1.18.1. `requirements.txt` records the tested Python package versions. Scientific ball arithmetic is in Arb/Acb through python-flint. NumPy/SciPy propose floating vectors for band tests; their positivity and Rayleigh tests are re-evaluated in ball arithmetic.

FMM2D is a separate install passed to `reproduce.py --fmm-root`. The exact tested source revision is in `FMM2D-source.json`. Build its MATLAB wrapper for the host architecture, then pass the directory containing `hfmm2d.m` and the matching `fmm2d` MEX binary. For a fresh external checkout at the recorded revision, upstream's build recipe is to select the platform make include and run `make matlab`. The tested installation has `make.inc.macos_arm64.gnu` settings: `gcc`, `g++`, `gfortran`, `-O3 -fPIC -arch arm64`, `-fopenmp`, and `-lgomp`; its wrapper is `fmm2d.mexmaca64`. A matching host setup can use, in that external checkout:

```sh
cp make.inc.macos_arm64.gnu make.inc
make matlab MEX="<MATLAB_MEX>"
```

Compiler and MATLAB MEX configuration are host prerequisites. The tested runs used an existing installation built this way; the build was not rerun for this package. No installed FMM files are copied into this package, and verify does not use FMM2D. The copy of its Apache-2.0 license is `FMM2D-LICENSE`.

Third-party licensing: python-flint's installed distribution declares MIT AND LGPL-3.0-or-later; FLINT uses LGPL-3.0-or-later. NumPy's installed distribution declares BSD-3-Clause AND 0BSD AND MIT AND Zlib AND CC0-1.0; SciPy's source license is BSD-3-Clause, with separate bundled component notices. MATLAB is proprietary and supplied by the user. These dependencies are external; their own licenses and binary-distribution notices apply. The project author's release license remains TODO in `../LICENSE`.
