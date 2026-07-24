# Extended search log

Search cutoff: **2026-07-21**. Discovery used web search, followed by journal,
DOI, HAL/arXiv, MathNet, Numdam, author-page, or open-full-text verification.

## Query families executed

The required query families were run in grouped searches, including:

- `photonic crystal waveguide band edge guided mode`, `line defect waveguide
  threshold mode`, `periodic waveguide spectral threshold`, `projected band
  edge line defect photonic crystal`;
- `Dirichlet-to-Neumann band edge periodic waveguide`, `Riccati equation band
  edge periodic waveguide`, `limiting absorption periodic waveguide band edge`;
- `Bloch multiplier unit circle periodic waveguide`, `defective Bloch
  multiplier`, `Jordan chain Bloch modes`, `generalized Floquet modes band
  edge`, `threshold resonance periodic operator waveguide`;
- `supercell convergence near band edge`, `PML band edge periodic waveguide`,
  `scattering matrix slow light numerical stability`;
- `leaky modes photonic crystal line defect waveguide`, `quasinormal modes
  photonic crystal line defect`, `complex frequency guided modes periodic
  waveguide`, `guided resonances line defect photonic crystal`;
- `boundary integral leaky modes photonic crystal`, `Muller integral equation
  photonic crystal resonances`, `boundary integral nonlinear eigenvalue
  photonic crystal`, `complex frequency quasiperiodic Green function`;
- `outgoing Bloch condition complex frequency periodic waveguide`, `scattering
  matrix poles periodic waveguide`, `analytic continuation DtN periodic
  waveguide`, `resolvent poles line defect periodic medium`;
- `Beyn method photonic crystal resonances`, `contour integral nonlinear
  eigenvalue photonic crystal`, `pole search scattering matrix photonic
  crystal`, `rational approximation nonlinear eigenvalue waveguide`;
- `BIC line defect photonic crystal waveguide`, `embedded eigenvalue periodic
  line defect`, `high Q resonance near BIC photonic crystal`.

Supplemental exact-intersection searches were `"complex frequency"
"Dirichlet-to-Neumann" "periodic waveguide" resonance`, `"analytic
continuation" Bloch trace periodic waveguide resonance`, `"periodic lead"
quasinormal mode`, and `Muller boundary integral line defect photonic crystal
resonance`.

## Backward and forward chaining

- **Fliss 2013 chain.** Backward to Joly--Li--Fliss and propagation/Riccati
  constructions; forward to Fliss--Joly (radiation), Fliss--Joly--Lescarret
  (DtN with periodic outlets), Kirsch--Lechleiter, Zhang's deformed-Bloch-
  contour numerics, and Kirsch--Schweizer. Result: the real-frequency outgoing
  theory is mature under nondegeneracy assumptions, but exact zero-group-
  velocity thresholds remain a separate singular regime.
- **Threshold chain.** Hoang's semi-infinite-guide LAP led forward to radiation-
  condition papers and Nazarov's classification of ordinary/degenerate
  thresholds and virtual levels. Result: a threshold resonance is not merely a
  slowly decaying gap mode.
- **Photonic BIE chain.** Haider--Shipman--Venakides led to Shipman--Venakides
  and resonant-transmission work. Result: second-kind boundary-integral
  dispersions already unify real bound states and complex slab resonances in a
  close, but not periodic-half-lead, geometry.
- **Leaky-waveguide chain.** Li--Lu's exact boundary conditions led to BIE mode
  solvers for photonic-crystal fibers and general optical waveguides. Result:
  “BIE computation of leaky modes” has high prior-art risk; the potential gap
  is branch-consistent periodic-lead trace continuation and certification.
- **NEP chain.** Beyn and scattering-matrix pole papers led to Riesz-projection,
  contour, rational-interpolation, and photonic BEM-NEP papers. Result: replacing
  a dense singular-value scan by a contour solver is not itself novel.
- **BIC chain.** Shipman/Venakides and Abdrabou/Lu show that a real bound state,
  a nearby complex-frequency resonance, and a fixed-real-frequency complex-
  propagation mode are different slices of a multivariable dispersion set.

## Verified new BibTeX sources

Each added key was checked against the following primary or bibliographic page:

| Key | Verification source |
|---|---|
| `Hoang2011LAP` | SIAM DOI `10.1137/100791798` |
| `FlissJoly2016Radiation` | Springer/HAL DOI `10.1007/s00205-015-0897-3` |
| `KirschLechleiter2018` | Wiley DOI `10.1002/mma.4879` |
| `LamaczSchweizer2018` | Numdam/ESAIM DOI `10.1051/m2an/2018026` |
| `FlissJolyLescarret2021` | MSP/Pure and Applied Analysis DOI `10.2140/paa.2021.3.487` |
| `Zhang2021NumericalWaveguides` | Springer DOI `10.1007/s00211-021-01229-0` |
| `KirschSchweizer2025` | Wiley DOI `10.1002/mma.10435` |
| `Nazarov2020Threshold` | MathNet DOI `10.1070/IM8928` |
| `HaiderShipmanVenakides2002` | SIAM DOI `10.1137/S003613990138531X` |
| `ShipmanVenakides2003` | SIAM DOI `10.1137/S0036139902411120` |
| `ShipmanVenakides2005` | APS DOI `10.1103/PhysRevE.71.026611` |
| `LiLu2009LeakyCavities` | Optica DOI `10.1364/JOSAB.26.002427` |
| `LiLu2010LeakyWaveguides` | IEEE DOI `10.1109/JLT.2009.2035062` |
| `LuLu2012PCF` | IEEE DOI `10.1109/JLT.2012.2189355` |
| `LaiJiang2018` | Elsevier DOI `10.1016/j.acha.2016.06.009` |
| `KristensenEtAl2014` | Optica/PubMed DOI `10.1364/OL.39.006359` |
| `BykovDoskolovich2013` | IEEE/Optica DOI `10.1109/JLT.2012.2234723` |
| `AbdrabouLu2019` | APS DOI `10.1103/PhysRevA.99.063818` |
| `AbdrabouLu2022` | APS DOI `10.1103/PhysRevA.106.013523` |
| `BrunoDelourme2014` | Elsevier DOI `10.1016/j.jcp.2013.12.047` |
| `MaiLu2022` | APS DOI `10.1103/PhysRevE.106.035304` |
| `PerrusselPoirier2024` | Elsevier DOI `10.1016/j.enganabound.2024.105928` |
| `Beyn2012` | Elsevier DOI `10.1016/j.laa.2011.03.030` |

## Negative/qualified result

No verified paper from these searches simultaneously supplied: the current
infinite transverse periodic half-leads, a central Müller interface operator,
an analytically continued complex-frequency Bloch Cauchy relation, a limiting
relation at unit-circle/threshold degeneracy, and a certified contour NEP.
This is a bounded search result, not a statement of firstness. Direct prior art
exists for every major component and for very close slab/fiber geometries.

