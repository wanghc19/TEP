# bie-fem-route

Abbreviations: BIE = boundary integral equation (边界积分方程); FEM = finite
element method (有限元法); DtN = Dirichlet-to-Neumann.

Beamer slides (Chinese) explaining why the BIE route is kept only as a
reference solution and is not continued as the reliable-enclosure route for
direction 1, compared with direct high-order FEM + DtN + Lehmann–Goerisch.

- `bie-fem-route.tex`: main file; build with `latexmk -xelatex bie-fem-route.tex`.

Evidence (every number on the slides comes from these records):

- `research/explorations/numerical-directions/bie-route-status.md`: guarantee
  form of each BIE result and the BIE cost records.
- `research/explorations/numerical-directions/bie-fem-io-facts.md`: inputs and
  outputs of both routes, error coverage, thread settings, model geometry.
- `research/explorations/numerical-directions/fem-search-provenance.md`: origin
  of the FEM starting frequency; same-window candidate search costs.
- `test/numerical-directions/fem-pipeline-v1/README.md`: one-process FEM
  pipeline from the gap window to the P3/RT3 interval (119.4 s, 11 threads).
- `test/numerical-directions/gap-ends-v1/README.md`: right-end search on
  k in [2.1875, 2.38] (5.8 s, no mode), gap endpoints 1.32^2 / 2.37^2, interval
  width 4.45e-9, endpoint inertia and surface-state floating-point checks.
- `test/i9/search-v1/README.md`, `test/i9/estimate-v1/README.md`: BIE search
  and evaluation costs and the estimate width.
